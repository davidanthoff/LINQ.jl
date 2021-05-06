using Query
using DataFrames

df = DataFrame(name=["John", "Sally", "Kirk"], age=[23., 42., 59.], children=[3,5,2])

x = @from i in df begin
    @let count = length(i.name)
    @let kids_per_year = i.children / i.age
    @where count > 4
    @select {Name = i.name, Count = count, KidsPerYear = kids_per_year}
    @collect DataFrame
end

println(x)
