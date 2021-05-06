using Query
using DataFrames

source = Dict("John" => 34., "Sally" => 56.)

result = @from i in source begin
         @where i.second > 36.
         @select {Name = lowercase(i.first)}
         @collect DataFrame
end

println(result)

result = @from i in source begin
         @where i.second > 36.
         @select {Name = lowercase(i.first)}
         @collect
end

println(result)
