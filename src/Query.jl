module Query

using NullableArrays
using Requires
using NamedTuples
using DataStructures
import FunctionWrappers: FunctionWrapper

import Base.start
import Base.next
import Base.done
import Base.collect
import Base.length
import Base.eltype
import Base.join

export @from, Grouping, null

include("operators.jl")

include("enumerable/enumerable.jl")
include("enumerable/enumerable_groupby.jl")
include("enumerable/enumerable_join.jl")
include("enumerable/enumerable_groupjoin.jl")
include("enumerable/enumerable_orderby.jl")
include("enumerable/enumerable_select.jl")
include("enumerable/enumerable_where.jl")
include("enumerable/enumerable_selectmany.jl")

include("queryable/queryable.jl")
include("queryable/queryable_select.jl")
include("queryable/queryable_where.jl")

include("query_translation.jl")

include("sources/source_array.jl")
include("sources/source_iterable.jl")
include("sources/source_dataframe.jl")
include("sources/source_sqlite.jl")
include("sources/source_typedtable.jl")
include("sources/source_datastream.jl")
include("sources/source_ndsparsedata.jl")

include("sinks/sink_array.jl")
include("sinks/sink_dataframe.jl")

macro from(range::Expr, body::Expr)
	if range.head!=:call || range.args[1]!=:in
		error()
	end

	if body.head!=:block
		error()
	end

	body.args = filter(i->i.head!=:line,body.args)

	insert!(body.args,1,:( @from $(range.args[2]) in $(range.args[3]) ))

	translate_query(body)

	return body.args[1]
end

macro where_internal(source, f)
	q = Expr(:quote, f)
    :(where($(esc(source)), $(esc(f)), $(esc(q))))
end

macro select_internal(source, f)
	q = Expr(:quote, f)
    :(select($(esc(source)), $(esc(f)), $(esc(q))))
end

macro orderby_internal(source, f)
	q = Expr(:quote, f)
    :(orderby($(esc(source)), $(esc(f)), $(esc(q))))
end

macro orderby_descending_internal(source, f)
	q = Expr(:quote, f)
    :(orderby_descending($(esc(source)), $(esc(f)), $(esc(q))))
end

macro thenby_internal(source, f)
	q = Expr(:quote, f)
    :(thenby($(esc(source)), $(esc(f)), $(esc(q))))
end

macro thenby_descending_internal(source, f)
	q = Expr(:quote, f)
    :(thenby_descending($(esc(source)), $(esc(f)), $(esc(q))))
end

macro join_internal(outer, inner, outerKeySelector, innerKeySelector, resultSelector)
	q_outerKeySelector = Expr(:quote, outerKeySelector)
	q_innerKeySelector = Expr(:quote, innerKeySelector)
	q_resultSelector = Expr(:quote, resultSelector)

	:(join($(esc(outer)), $(esc(inner)), $(esc(outerKeySelector)), $(esc(q_outerKeySelector)), $(esc(innerKeySelector)),$(esc(q_innerKeySelector)), $(esc(resultSelector)),$(esc(q_resultSelector))))
end

macro group_join_internal(outer, inner, outerKeySelector, innerKeySelector, resultSelector)
	q_outerKeySelector = Expr(:quote, outerKeySelector)
	q_innerKeySelector = Expr(:quote, innerKeySelector)
	q_resultSelector = Expr(:quote, resultSelector)

	:(group_join($(esc(outer)), $(esc(inner)), $(esc(outerKeySelector)), $(esc(q_outerKeySelector)), $(esc(innerKeySelector)),$(esc(q_innerKeySelector)), $(esc(resultSelector)),$(esc(q_resultSelector))))
end

macro select_many_internal(source,collectionSelector,resultSelector)
	q_collectionSelector = Expr(:quote, collectionSelector)
	q_resultSelector = Expr(:quote, resultSelector)

	:(select_many($(esc(source)), $(esc(collectionSelector)), $(esc(q_collectionSelector)), $(esc(resultSelector)), $(esc(q_resultSelector))))
end

macro group_by_internal(source,elementSelector,resultSelector)
	q_elementSelector = Expr(:quote, elementSelector)
	q_resultSelector = Expr(:quote, resultSelector)

	:(group_by($(esc(source)), $(esc(elementSelector)), $(esc(q_elementSelector)), $(esc(resultSelector)), $(esc(q_resultSelector))))
end

macro group_by_internal_simple(source,elementSelector)
	q_elementSelector = Expr(:quote, elementSelector)

	:(group_by($(esc(source)), $(esc(elementSelector)), $(esc(q_elementSelector))))
end

end # module
