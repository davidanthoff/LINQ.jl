using DataFrames

n = 10_000_000

# Right now things only work columns of type Array, so
# we need this slighlty cumbersome DataFrame construction
# to prevent DataArray or NullableArray creation
# We are also skipping all Strings because of #14955 (I think)
data_friends = fill(4, n)
data_age = fill(38.2, n)
data_children = fill(2, n)

columns = []
push!(columns, data_friends)
push!(columns, data_age)
push!(columns, data_children)

df = DataFrame(columns, [:friends, :age, :children])
