struct QueryException <: Exception
	msg::String
	context::Any
	QueryException(msg::AbstractString, context=nothing) = new(msg, context)
end

function Base.showerror(io::IO, ex::QueryException)
	print(io, "QueryException: $(ex.msg)")
	if ex.context !== nothing
		print(io, " at $(ex.context)")
	end
end

function helper_namedtuples_replacement(ex)
	return postwalk(ex) do x
		if x isa Expr && x.head==:braces
			new_ex = Expr(:tuple, x.args...)

			for (j,field_in_NT) in enumerate(new_ex.args)
				if isa(field_in_NT, Expr) && field_in_NT.head==:.
					name_to_use = field_in_NT.args[2].value
					new_ex.args[j] = Expr(:(=), name_to_use, field_in_NT)
				elseif isa(field_in_NT, Symbol)
					new_ex.args[j] = Expr(:(=), field_in_NT, field_in_NT)
				end
			end

			return new_ex
		else
			return x
		end
	end
end

function helper_replace_anon_func_syntax(ex)
	if !(isa(ex, Expr) && ex.head==:->)
		new_symb = gensym()
		new_symb2 = gensym()
		two_args = false
		new_ex = postwalk(ex) do x
			if isa(x, Symbol)
				if x==:_
					return new_symb
				elseif x==:__
					two_args = true
					return new_symb2
				else
					return x
				end
			else
				return x
			end
		end

		if two_args
			return :(($new_symb, $new_symb2) -> $(new_ex) )
		else
			return :($new_symb -> $(new_ex) )
		end
	else
		return ex
	end
end

function helper_replace_field_extraction_syntax(ex)
	postwalk(ex) do x
		iscall(x, :(..)) ? :(map(i->i.$(x.args[3]), $(x.args[2]))) : x
	end
end

function query_expression_translation_phase_A(qe)
	i = 1
	while i<=length(qe)
		clause = qe[i]
		# macrotools doesn't like underscores
		if ismacro(clause, Symbol("@left_outer_join")) && @capture clause @amacro_ rangevariable_ in source_ args__
			clause.args[1] = Symbol("@join")
			temp_name = gensym()
			push!(clause.args, :into)
			push!(clause.args, temp_name)
			nested_from = :(@from $rangevariable in QueryOperators.default_if_empty($temp_name))
			insert!(qe,i+1,nested_from)
		end
		i+=1
	end

	for i in eachindex(qe)
		qe[i] = helper_replace_field_extraction_syntax(qe[i])
	end
end

function query_expression_translation_phase_B(qe)
	i = 1
	while i<=length(qe)
		qe[i] = helper_namedtuples_replacement(qe[i])
		clause = qe[i]

		# for l=length(clause.args):-1:1
		# 	if clause.args[l] isa LineNumberNode
		# 		deleteat!(clause.args,l)
		# 	end
		# end

		if i==1 && @capture clause @from rangevariable_ in source_
			# Handle the case of a nested query. We are essentially detecting
			# here that the subquery starts with convert2nullable
			# and then we don't escape things.
			if @capture source Query.something_(args__)
				clause.args[3].args[3] = :(QueryOperators.query($(source)))
			elseif !(@capture source @QueryOperators.something_ args__)
				clause.args[3].args[3] = :(QueryOperators.query($(esc(source))))
			end
		elseif @capture clause @from rangevariable_ in source_
			clause.args[3].args[3] = :(QueryOperators.query($source))
		elseif @capture clause @join rangevariable_ in source_ args__
			clause.args[3].args[3] = :(QueryOperators.query($(esc(source))))
		end
		i+=1
	end
end

function query_expression_translation_phase_1(qe)
	done = false
	while !done
		group_into_index = findfirst(i->ismacro(i, "@group", 6) && i.args[6]==:into, qe)
		select_into_index = findfirst(i->ismacro(i, "@select", 4) && i.args[4]==:into, qe)
		if length(qe)>=2 && ismacro(qe[1], "@from") && group_into_index!==nothing
			x = qe[group_into_index].args[7]

			sub_query = Expr(:block, qe[1:group_into_index]...)

			deleteat!(sub_query.args[end].args,7)
			deleteat!(sub_query.args[end].args,6)

			translate_query(sub_query)

			length(sub_query.args)==1 || throw(QueryException("@group ... into subquery too long", sub_query))

			qe[1] = :( @from $x in $(sub_query.args[1]) )
			deleteat!(qe, 2:group_into_index)
		elseif length(qe)>=2 && ismacro(qe[1], "@from") && select_into_index!==nothing
			x = qe[select_into_index].args[5]

			sub_query = Expr(:block, qe[1:select_into_index]...)
			deleteat!(sub_query.args[end].args,5)
			deleteat!(sub_query.args[end].args,4)

			translate_query(sub_query)

			length(sub_query.args)==1 || throw(QueryException("@select ... into subquery too long", sub_query))

			qe[1] = :( @from $x in $(sub_query.args[1]) )
			deleteat!(qe, 2:select_into_index)
		else
			done = true
		end
	end
end

function query_expression_translation_phase_3(qe)
	done = false
	while !done
		if length(qe)>=2 &&
		   (@capture qe[1] @from rangevariable_ in source_) &&
		   (@capture qe[2] @select condition_) &&
		   condition == source

			qe[1] = :( QueryOperators.@map($source,identity) )
			deleteat!(qe,2)
		else
			done = true
		end
	end
end

function attribute_and_direction(sort_clause)
	if @capture sort_clause descending(attribute_)
		attribute, :descending
	elseif @capture sort_clause ascending(attribute_)
		attribute, :ascending
	else
		sort_clause, :ascending
	end
end

function query_expression_translation_phase_4(qe)
	done = false
	while !done
		if length(qe)>=3 && (@capture qe[1] @from rangevariable1_ in source1_) && (@capture qe[2] @from rangevariable2_ in source2_)
			f_collection_selector = anon(qe[2], rangevariable1, source2)
			f_arguments = Expr(:tuple,rangevariable1,rangevariable2)
			if (@capture qe[3] @select condition_)
				f_result_selector = anon(qe[3], f_arguments, condition)

				qe[1] = :( QueryOperators.@mapmany($source1, $(esc(f_collection_selector)), $(esc(f_result_selector))) )
				deleteat!(qe,3)
			else
				f_result_selector = anon(qe[3], f_arguments, :(($rangevariable1=$rangevariable1,$rangevariable2=$rangevariable2)))

				qe[1].args[3].args[2] = Expr(:transparentidentifier, gensym(:t), rangevariable1, rangevariable2)
				qe[1].args[3].args[3] = :( QueryOperators.@mapmany($source1, $(esc(f_collection_selector)), $(esc(f_result_selector))) )
			end
			deleteat!(qe,2)
		elseif length(qe)>=3 && (@capture qe[1] @from rangevariable1_ in source1_) && (@capture qe[2] @let rangevariable2_ = valueselector_)
			f_selector = anon(qe[3], rangevariable1, :(($rangevariable1=$rangevariable1,$rangevariable2=$valueselector)))

			qe[1].args[3].args[2] = Expr(:transparentidentifier, gensym(:t), rangevariable1, rangevariable2)
			qe[1].args[3].args[3] = :( QueryOperators.@map($source1,$(esc(f_selector))) )
			deleteat!(qe,2)
		elseif length(qe)>=3 && (@capture qe[1] @from rangevariable1_ in source1_) && (@capture qe[2] @where condition_)
			f_condition = anon(qe[2], rangevariable1, condition)

			qe[1].args[3].args[3] = :( QueryOperators.@filter($source1,$(esc(f_condition))) )
			deleteat!(qe,2)
		elseif length(qe)>=3 && (@capture qe[1] @from rangevariable1_ in source1_) && (@capture qe[2] @join rangevariable2_ in source2_ on leftkey_ equals rightkey_)
			f_outer_key = anon(qe[2], rangevariable1, leftkey)
			f_inner_key = anon(qe[2], rangevariable2, rightkey)
			f_arguments = Expr(:tuple,rangevariable1,rangevariable2)
			if (@capture qe[3] @select condition_)
				f_result = anon(qe[3], f_arguments, condition)
				qe[1] = :(
					QueryOperators.@join($source1, $source2, $(esc(f_outer_key)), $(esc(f_inner_key)), $(esc(f_result)))
					)

				deleteat!(qe,3)
			else
				f_result = anon(qe[2], f_arguments, :(($rangevariable1=$rangevariable1,$rangevariable2=$rangevariable2)) )

				qe[1].args[3].args[2] = Expr(:transparentidentifier, gensym(:t), rangevariable1, rangevariable2)
				qe[1].args[3].args[3] = :( QueryOperators.@join($source1,$source2,$(esc(f_outer_key)), $(esc(f_inner_key)), $(esc(f_result))) )

			end
			deleteat!(qe,2)
		elseif length(qe)>=3 && (@capture qe[1] @from rangevariable1_ in source1_) && (@capture qe[2] @join rangevariable2_ in source2_ on leftkey_ equals rightkey_ into groupvariable_)
			f_outer_key = anon(qe[2], rangevariable1, leftkey)
			f_inner_key = anon(qe[2], rangevariable2, rightkey)
			f_arguments = Expr(:tuple,rangevariable1,groupvariable)
			if (@capture qe[3] @select condition_)
				f_result = anon(qe[3], f_arguments, condition)
				qe[1] = :( QueryOperators.@groupjoin($source1, $source2, $(esc(f_outer_key)), $(esc(f_inner_key)), $(esc(f_result))) )

				deleteat!(qe,3)
			else
				f_result = anon(qe[2], f_arguments, :(($rangevariable1=$rangevariable1,$groupvariable=$groupvariable)) )

				qe[1].args[3].args[2] = Expr(:transparentidentifier, gensym(:t), rangevariable1, groupvariable)
				qe[1].args[3].args[3] = :( QueryOperators.@groupjoin($source1,$source2,$(esc(f_outer_key)), $(esc(f_inner_key)), $(esc(f_result))) )
			end
			deleteat!(qe,2)
		elseif length(qe)>=3 && (@capture qe[1] @from rangevariable1_ in source1_) && (@capture qe[2] @orderby sortclause_)
			ks = []
			if @capture sortclause (sortclauses__,)
				for sort_clause in sortclauses
					push!(ks, attribute_and_direction(sort_clause))
				end
			else
				push!(ks, attribute_and_direction(sortclause))
			end

			for (i,sort_clause) in enumerate(ks)
				f_condition = anon(qe[2], rangevariable1, sort_clause[1])

				if sort_clause[2]==:ascending
					if i==1
						qe[1].args[3].args[3] = :( QueryOperators.@orderby($source1,$(esc(f_condition))) )
					else
						qe[1].args[3].args[3] = :( QueryOperators.@thenby($source1,$(esc(f_condition))) )
					end
				elseif sort_clause[2]==:descending
					if i==1
						qe[1].args[3].args[3] = :( QueryOperators.@orderby_descending($source1,$(esc(f_condition))) )
					else
						qe[1].args[3].args[3] = :( QueryOperators.@thenby_descending($(qe[1].args[3].args[3]),$(esc(f_condition))) )
					end
				end
			end
			deleteat!(qe,2)
		else
			done = true
		end
	end
end

function query_expression_translation_phase_5(qe)
	i = 1
	while i<=length(qe)
		if @capture qe[i] @select condition_
			from_clause = qe[i-1]
			if @capture from_clause @from rangevariable_ in source_
				if condition==rangevariable
					qe[i-1] = source
				else
					func_call = Expr(:->, rangevariable, condition)
					qe[i-1] = :( QueryOperators.@map($source, $(esc(func_call))) )
				end
				deleteat!(qe,i)
		    else
				throw(QueryException("Phase 5: expected @from before @select", from_clause))
			end
		else
			i+=1
		end
	end
end

function query_expression_translation_phase_6(qe)
	done = false
	while !done
		if (@capture qe[1] @from rangevariable_ in source_) && (@capture qe[2] @group elementselector_ by keyselector_ args__)
			f_elementSelector = Expr(:->, rangevariable, keyselector)
			f_resultSelector = Expr(:->, rangevariable, elementselector)

			if elementselector == rangevariable
				qe[1] = :( QueryOperators.@groupby_simple($source, $(esc(f_elementSelector))) )
			else
				qe[1] = :( QueryOperators.@groupby($source, $(esc(f_elementSelector)), $(esc(f_resultSelector))) )
			end
			deleteat!(qe,2)
		else
			done = true
		end
	end
end

# Phase 7

function replace_transparent_identifier_in_anonym_func(ex::Expr, names_to_put_in_scope)
	for (i,child_ex) in enumerate(ex.args)
		if isa(child_ex, Expr)
			replace_transparent_identifier_in_anonym_func(child_ex, names_to_put_in_scope)
		elseif isa(child_ex, Symbol)
			index_of_name = findfirst(j->child_ex==j[2], names_to_put_in_scope)
			if index_of_name!==nothing && !(ex.head==Symbol("=>") && i==1)
				ex.args[i] = Expr(:., names_to_put_in_scope[index_of_name][1], QuoteNode(child_ex))
			end
		end
	end
end

function find_names_to_put_in_scope(ex::Expr)
	names = []
	for child_ex in ex.args[2:end]
		if isa(child_ex,Expr) && child_ex.head==:transparentidentifier
			child_names = find_names_to_put_in_scope(child_ex)
			for child_name in child_names
				push!(names, (Expr(:., ex.args[1], QuoteNode(child_name[1])), child_name[2]))
			end
		elseif isa(child_ex, Symbol)
			push!(names,(ex.args[1],child_ex))
		elseif isa(child_ex, Expr) && child_ex.head==:.
			push!(names,(ex.args[1],child_ex.args[2].value))
		else
			throw(QueryException("identifier expected", child_ex))
		end
	end
	return names
end

function find_and_translate_transparent_identifier(ex::Expr)
	# First expand any transparent identifiers in lambdas
	if ex.head==:-> && isa(ex.args[1], Expr) && ex.args[1].head==:transparentidentifier
		names_to_put_in_scope = find_names_to_put_in_scope(ex.args[1])
		ex.args[1] = ex.args[1].args[1]
		replace_transparent_identifier_in_anonym_func(ex, names_to_put_in_scope)
	elseif ex.head==:-> && isa(ex.args[1], Expr) && ex.args[1].head==:tuple
		names_to_put_in_scope = []
		for (i, child_ex) in enumerate(ex.args[1].args)
			if isa(child_ex, Expr) && child_ex.head==:transparentidentifier
				append!(names_to_put_in_scope, find_names_to_put_in_scope(child_ex))
				ex.args[1].args[i] = child_ex.args[1]
			end
		end
		replace_transparent_identifier_in_anonym_func(ex, names_to_put_in_scope)
	end


	for (i,child_ex) in enumerate(ex.args)
		if isa(child_ex, Expr) && child_ex.head==:transparentidentifier
			ex.args[i] = child_ex.args[1]
		elseif isa(child_ex, Expr)
			find_and_translate_transparent_identifier(child_ex)
		end
	end
end

function query_expression_translation_phase_7(qe)
	for clause in qe
		isa(clause, Expr) && find_and_translate_transparent_identifier(clause)
	end
end

function query_expression_translation_phase_D(qe)
	i = 1
	while i<=length(qe)
		clause = qe[i]
		if @capture clause @collect args__
			previous_clause = qe[i-1]
			if @capture clause @collect sink_
			    qe[i-1] = :( collect($previous_clause, $(esc(sink))) )
			elseif @capture clause @collect
			    qe[i-1] = :( collect($previous_clause) )
			end
			deleteat!(qe,i)
		else
			i+=1
		end
	end
end

function translate_query(body)
	debug_output = true

	debug_output && println("AT START")
	debug_output && println(body)

	query_expression_translation_phase_1(body.args)
	debug_output && println("AFTER 1")
	debug_output && println(body)

	query_expression_translation_phase_A(body.args)
	debug_output && println("AFTER A")
	debug_output && println(body)

	query_expression_translation_phase_B(body.args)
	debug_output && println("AFTER B")
	debug_output && println(body)

	query_expression_translation_phase_3(body.args)
	debug_output && println("AFTER 3")
	debug_output && println(body)

	query_expression_translation_phase_4(body.args)
	debug_output && println("AFTER 4")
	debug_output && println(body)

	query_expression_translation_phase_5(body.args)
	debug_output && println("AFTER 5")
	debug_output && println(body)

	query_expression_translation_phase_6(body.args)
	debug_output && println("AFTER 6")
	debug_output && println(body)

	query_expression_translation_phase_7(body.args)
	debug_output && println("AFTER 7")
	debug_output && println(body)

	query_expression_translation_phase_D(body.args)
	debug_output && println("AFTER D")
	debug_output && println(body)
end
