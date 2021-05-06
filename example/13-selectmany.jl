using DataFrames, Query

df1 = DataFrame(a=[1,2,3], b=[1.,2.,3.])
df2 = DataFrame(c=[2.,4.,2.], d=["John", "Jim","Sally"])

q = @from i in df1 begin
    @from j in df2
    @select {i.a,i.b,j.c,j.d}
    @collect DataFrame
end

println(q)

source_dict = Dict(:a => [1,2,3], :b => [4,5])

q = @from i in source_dict begin
	@from j in i.second
	@select {Key = i.first,Value = j}
	@collect DataFrame
end

println(q)
