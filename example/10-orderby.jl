using Query
using DataFrames

df = DataFrame(name=["John", "Sally", "Kirk"], age=[23., 42., 59.], children=[3,5,2])

x = @from i in df begin
    @orderby i.age
    @select {Name = lowercase(i.name)}
    @collect DataFrame
end

println(x)

x = @from i in df begin
    @orderby descending(i.age)
    @select {Name = lowercase(i.name)}
    @collect DataFrame
end

println(x)

x = @from i in df begin
    @orderby ascending(i.age)
    @select {Name = lowercase(i.name)}
    @collect DataFrame
end

println(x)
