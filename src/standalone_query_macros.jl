macro count(source, f)
    q = Expr(:quote, f)
    :(QueryOperators.count(QueryOperators.query($(esc(source))), $(esc(f)), $(esc(q))))
end

macro count(source)
    :(QueryOperators.count(QueryOperators.query($(esc(source)))))
end

macro count()
    :( i -> QueryOperators.count(QueryOperators.query(i)))
end

macro groupby(source, elementSelector, resultSelector)
    elementSelector_as_anonym_func = helper_replace_anon_func_syntax(elementSelector)
    resultSelector_as_anonym_func = helper_replace_anon_func_syntax(resultSelector)

 	q_elementSelector = Expr(:quote, elementSelector_as_anonym_func)
	q_resultSelector = Expr(:quote, resultSelector_as_anonym_func)

    return :(QueryOperators.groupby(QueryOperators.query($(esc(source))), $(esc(elementSelector_as_anonym_func)), $(esc(q_elementSelector)), $(esc(resultSelector_as_anonym_func)), $(esc(q_resultSelector)))) |>
        helper_namedtuples_replacement
end

macro groupby(elementSelector, resultSelector)
    elementSelector_as_anonym_func = helper_replace_anon_func_syntax(elementSelector)
    resultSelector_as_anonym_func = helper_replace_anon_func_syntax(resultSelector)

 	q_elementSelector = Expr(:quote, elementSelector_as_anonym_func)
	q_resultSelector = Expr(:quote, resultSelector_as_anonym_func)

    return :( i -> QueryOperators.groupby(QueryOperators.query(i), $(esc(elementSelector_as_anonym_func)), $(esc(q_elementSelector)), $(esc(resultSelector_as_anonym_func)), $(esc(q_resultSelector)))) |>
        helper_namedtuples_replacement
end

macro groupby(elementSelector)
    elementSelector_as_anonym_func = helper_replace_anon_func_syntax(elementSelector)
    resultSelector_as_anonym_func = :(i -> i)

 	q_elementSelector = Expr(:quote, elementSelector_as_anonym_func)
	q_resultSelector = Expr(:quote, resultSelector_as_anonym_func)

    return :( i -> QueryOperators.groupby(QueryOperators.query(i), $(esc(elementSelector_as_anonym_func)), $(esc(q_elementSelector)), $(esc(resultSelector_as_anonym_func)), $(esc(q_resultSelector)))) |>
        helper_namedtuples_replacement
end

macro groupjoin(outer, inner, outerKeySelector, innerKeySelector, resultSelector)
    outerKeySelector_as_anonym_func = helper_replace_anon_func_syntax(outerKeySelector)
    innerKeySelector_as_anonym_func = helper_replace_anon_func_syntax(innerKeySelector)
    resultSelector_as_anonym_func = helper_replace_anon_func_syntax(resultSelector)

    q_outerKeySelector = Expr(:quote, outerKeySelector_as_anonym_func)
    q_innerKeySelector = Expr(:quote, innerKeySelector_as_anonym_func)
    q_resultSelector = Expr(:quote, resultSelector_as_anonym_func)

    return :(QueryOperators.groupjoin(QueryOperators.query($(esc(outer))), 
            QueryOperators.query($(esc(inner))), 
            $(esc(outerKeySelector_as_anonym_func)), $(esc(q_outerKeySelector)),
            $(esc(innerKeySelector_as_anonym_func)), $(esc(q_innerKeySelector)),
            $(esc(resultSelector_as_anonym_func)), $(esc(q_resultSelector)),)) |>
        helper_namedtuples_replacement
end

macro groupjoin(inner, outerKeySelector, innerKeySelector, resultSelector)
    outerKeySelector_as_anonym_func = helper_replace_anon_func_syntax(outerKeySelector)
    innerKeySelector_as_anonym_func = helper_replace_anon_func_syntax(innerKeySelector)
    resultSelector_as_anonym_func = helper_replace_anon_func_syntax(resultSelector)

    q_outerKeySelector = Expr(:quote, outerKeySelector_as_anonym_func)
    q_innerKeySelector = Expr(:quote, innerKeySelector_as_anonym_func)
    q_resultSelector = Expr(:quote, resultSelector_as_anonym_func)

    return :( outer -> QueryOperators.groupjoin(QueryOperators.query(outer), 
            QueryOperators.query($(esc(inner))), 
            $(esc(outerKeySelector_as_anonym_func)), $(esc(q_outerKeySelector)),
            $(esc(innerKeySelector_as_anonym_func)), $(esc(q_innerKeySelector)),
            $(esc(resultSelector_as_anonym_func)), $(esc(q_resultSelector)),)) |>
        helper_namedtuples_replacement
end

macro join(outer, inner, outerKeySelector, innerKeySelector, resultSelector)
    outerKeySelector_as_anonym_func = helper_replace_anon_func_syntax(outerKeySelector)
    innerKeySelector_as_anonym_func = helper_replace_anon_func_syntax(innerKeySelector)
    resultSelector_as_anonym_func = helper_replace_anon_func_syntax(resultSelector)

    q_outerKeySelector = Expr(:quote, outerKeySelector_as_anonym_func)
    q_innerKeySelector = Expr(:quote, innerKeySelector_as_anonym_func)
    q_resultSelector = Expr(:quote, resultSelector_as_anonym_func)

    return :(QueryOperators.join(QueryOperators.query($(esc(outer))), 
            QueryOperators.query($(esc(inner))), 
            $(esc(outerKeySelector_as_anonym_func)), $(esc(q_outerKeySelector)),
            $(esc(innerKeySelector_as_anonym_func)), $(esc(q_innerKeySelector)),
            $(esc(resultSelector_as_anonym_func)), $(esc(q_resultSelector)),)) |>
        helper_namedtuples_replacement
end

macro join(inner, outerKeySelector, innerKeySelector, resultSelector)
    outerKeySelector_as_anonym_func = helper_replace_anon_func_syntax(outerKeySelector)
    innerKeySelector_as_anonym_func = helper_replace_anon_func_syntax(innerKeySelector)
    resultSelector_as_anonym_func = helper_replace_anon_func_syntax(resultSelector)

    q_outerKeySelector = Expr(:quote, outerKeySelector_as_anonym_func)
    q_innerKeySelector = Expr(:quote, innerKeySelector_as_anonym_func)
    q_resultSelector = Expr(:quote, resultSelector_as_anonym_func)

    return :( outer -> QueryOperators.join(QueryOperators.query(outer), 
            QueryOperators.query($(esc(inner))), 
            $(esc(outerKeySelector_as_anonym_func)), $(esc(q_outerKeySelector)),
            $(esc(innerKeySelector_as_anonym_func)), $(esc(q_innerKeySelector)),
            $(esc(resultSelector_as_anonym_func)), $(esc(q_resultSelector)),)) |>
        helper_namedtuples_replacement
end

macro orderby(source, f)
    f_as_anonym_func = helper_replace_anon_func_syntax(f)
    q = Expr(:quote, f_as_anonym_func)
    return :(QueryOperators.orderby(QueryOperators.query($(esc(source))), $(esc(f_as_anonym_func)), $(esc(q)))) |>
        helper_namedtuples_replacement
end

macro orderby(f)
    f_as_anonym_func = helper_replace_anon_func_syntax(f)
    q = Expr(:quote, helper_replace_anon_func_syntax(f_as_anonym_func))
    return :( i -> QueryOperators.orderby(QueryOperators.query(i), $(esc(f_as_anonym_func)), $(esc(q)))) |>
        helper_namedtuples_replacement
end

macro orderby_descending(source, f)
    f_as_anonym_func = helper_replace_anon_func_syntax(f)
    q = Expr(:quote, f_as_anonym_func)
    return :(QueryOperators.orderby_descending(QueryOperators.query($(esc(source))), $(esc(f_as_anonym_func)), $(esc(q)))) |>
        helper_namedtuples_replacement
end

macro orderby_descending(f)
    f_as_anonym_func = helper_replace_anon_func_syntax(f)
    q = Expr(:quote, helper_replace_anon_func_syntax(f_as_anonym_func))
    return :( i -> QueryOperators.orderby_descending(QueryOperators.query(i), $(esc(f_as_anonym_func)), $(esc(q)))) |>
        helper_namedtuples_replacement
end

macro thenby(source, f)
    f_as_anonym_func = helper_replace_anon_func_syntax(f)
    q = Expr(:quote, f_as_anonym_func)
    return :(QueryOperators.thenby($(esc(source)), $(esc(f_as_anonym_func)), $(esc(q)))) |>
        helper_namedtuples_replacement
end

macro thenby(f)
    f_as_anonym_func = helper_replace_anon_func_syntax(f)
    q = Expr(:quote, helper_replace_anon_func_syntax(f_as_anonym_func))
    return :( i -> QueryOperators.thenby(i, $(esc(f_as_anonym_func)), $(esc(q)))) |>
        helper_namedtuples_replacement
end

macro thenby_descending(source, f)
    f_as_anonym_func = helper_replace_anon_func_syntax(f)
    q = Expr(:quote, f_as_anonym_func)
    return :(QueryOperators.thenby_descending($(esc(source)), $(esc(f_as_anonym_func)), $(esc(q)))) |>
        helper_namedtuples_replacement
end

macro thenby_descending(f)
    f_as_anonym_func = helper_replace_anon_func_syntax(f)
    q = Expr(:quote, helper_replace_anon_func_syntax(f_as_anonym_func))
    return :( i -> QueryOperators.thenby_descending(i, $(esc(f_as_anonym_func)), $(esc(q)))) |>
        helper_namedtuples_replacement
end

macro map(source, f)
    f_as_anonym_func = helper_replace_anon_func_syntax(f)
    q = Expr(:quote, f_as_anonym_func)
    return :(QueryOperators.map(QueryOperators.query($(esc(source))), $(esc(f_as_anonym_func)), $(esc(q)))) |>
        helper_namedtuples_replacement
end

macro map(f)
    f_as_anonym_func = helper_replace_anon_func_syntax(f)
    q = Expr(:quote, f_as_anonym_func)
    return :( i -> QueryOperators.map(QueryOperators.query(i), $(esc(f_as_anonym_func)), $(esc(q))) ) |>
        helper_namedtuples_replacement
end

macro mapmany(source, collectionSelector, resultSelector)
    collectionSelector_as_anonym_func = helper_replace_anon_func_syntax(collectionSelector)
    resultSelector_as_anonym_func = helper_replace_anon_func_syntax(resultSelector)

    collectionSelector_q = Expr(:quote, collectionSelector_as_anonym_func)
    resultSelector_q = Expr(:quote, resultSelector_as_anonym_func)

    return :(QueryOperators.mapmany(QueryOperators.query($(esc(source))),
            $(esc(collectionSelector_as_anonym_func)), $(esc(collectionSelector_q)),
            $(esc(resultSelector_as_anonym_func)), $(esc(resultSelector_q)))) |>
        helper_namedtuples_replacement
end

macro mapmany(collectionSelector, resultSelector)
    collectionSelector_as_anonym_func = helper_replace_anon_func_syntax(collectionSelector)
    resultSelector_as_anonym_func = helper_replace_anon_func_syntax(resultSelector)

    collectionSelector_q = Expr(:quote, collectionSelector_as_anonym_func)
    resultSelector_q = Expr(:quote, resultSelector_as_anonym_func)

    return :( i -> QueryOperators.mapmany(QueryOperators.query(i),
            $(esc(collectionSelector_as_anonym_func)), $(esc(collectionSelector_q)),
            $(esc(resultSelector_as_anonym_func)), $(esc(resultSelector_q)))) |>
        helper_namedtuples_replacement
end

macro filter(source, f)
    f_as_anonym_func = helper_replace_anon_func_syntax(f)
    q = Expr(:quote, f_as_anonym_func)
    return :(QueryOperators.filter(QueryOperators.query($(esc(source))), $(esc(f_as_anonym_func)), $(esc(q)))) |>
        helper_namedtuples_replacement
end

macro filter(f)
    f_as_anonym_func = helper_replace_anon_func_syntax(f)
    q = Expr(:quote, helper_replace_anon_func_syntax(f_as_anonym_func))
    return :( i -> QueryOperators.filter(QueryOperators.query(i), $(esc(f_as_anonym_func)), $(esc(q)))) |>
        helper_namedtuples_replacement
end

macro take(source, n)
    return :(QueryOperators.take(QueryOperators.query($(esc(source))), $(esc(n))))
end

macro take(n)
    return :( i -> QueryOperators.take(QueryOperators.query(i), $(esc(n))))
end

macro drop(source, n)
    return :(QueryOperators.drop(QueryOperators.query($(esc(source))), $(esc(n))))
end

macro drop(n)
    return :( i -> QueryOperators.drop(QueryOperators.query(i), $(esc(n))))
end

macro unique()
    return :( i -> QueryOperators.unique(QueryOperators.query(i), q -> q, :(q -> q))) |>
        helper_namedtuples_replacement
end

macro unique(f)
    f_as_anonym_func = helper_replace_anon_func_syntax(f)
    q = Expr(:quote, helper_replace_anon_func_syntax(f_as_anonym_func))
    return :( i -> QueryOperators.unique(QueryOperators.query(i), $(esc(f_as_anonym_func)), $(esc(q)))) |>
        helper_namedtuples_replacement
end
