using Query
using DataFrames

struct Person
    Name::String
    Friends::Vector{String}
end

source = Array{Person}(undef, 0)
push!(source, Person("John", ["Sally", "Miles", "Frank"]))
push!(source, Person("Sally", ["Don", "Martin"]))

result = @from i in source begin
         @where length(i.Friends) > 2
         @select {i.Name, Friendcount = length(i.Friends)}
         @collect
end

println(result)

result = @from i in source begin
         @where length(i.Friends) > 2
         @select {i.Name, Friendcount = length(i.Friends)}
         @collect DataFrame
end

println(result)
