using Query
using DataFrames

df = DataFrame(a=[2,1,1,2,1,3], b=[2,2,1,1,3,2])

x = @from i in df begin
    @orderby descending(i.a), i.b
    @select i
    @collect DataFrame
end

println(x)
