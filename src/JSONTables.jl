module JSONTables

using JSON3, Tables

export jsontable

# read

struct Table{columnar, T}
    source::T
end

function jsontable(source)
    x = JSON3.read(source)
    columnar = x isa JSON3.Object
    columnar || x isa JSON3.Array || throw(ArgumentError("input json source is not a table"))
    return Table{columnar, typeof(x)}(x)
end

Tables.istable(::Type{<:Table}) = true

# columnar source
Tables.columnaccess(::Type{Table{true, T}}) where {T} = true
Tables.columns(x::Table{true}) = x

Base.propertynames(x::Table{true}) = Tuple(keys(getfield(x, :source)))
Base.getproperty(x::Table{true}, nm::Symbol) = getproperty(getfield(x, :source), nm)

# row source
Tables.rowaccess(::Type{Table{false, T}}) where {T} = true
Tables.rows(x::Table{false}) = x

Base.IteratorSize(::Type{Table{false, T}}) where {T} = Base.HasLength()
Base.length(x::Table{false}) = length(x.source)
Base.IteratorEltype(::Type{Table{false, T}}) where {T} = Base.HasEltype()
Base.eltype(x::Table{false, JSON3.Array{T}}) where {T} = T

Base.iterate(x::Table{false}) = iterate(x.source)
Base.iterate(x::Table{false}, st) = iterate(x.source, st)

# write
struct ObjectTable{T}
    x::T
end

JSON3.StructType(::Type{<:ObjectTable}) = JSON3.ObjectType()
Base.pairs(x::ObjectTable) = zip(propertynames(x.x), Tables.eachcolumn(x.x))

struct ArrayTable{T}
    x::T
end

JSON3.StructType(::Type{<:ArrayTable}) = JSON3.ArrayType()

struct ArrayRow{T}
    x::T
end

JSON3.StructType(::Type{<:ArrayRow}) = JSON3.ObjectType()
Base.pairs(x::ArrayRow) = zip(propertynames(x.x), Tables.eachcolumn(x.x))

Base.IteratorSize(::Type{ArrayTable{T}}) where {T} = IteratorSize(T)
Base.length(x::ArrayTable) = length(x.x)

function Base.iterate(x::ArrayTable)
    state = iterate(x.x)
    state === nothing && return nothing
    return ArrayRow(state[1]), state[2]
end

function Base.iterate(x::ArrayTable, st)
    state = iterate(x.x, st)
    state === nothing && return nothing
    return ArrayRow(state[1]), state[2]
end

objecttable(table) = JSON3.write(ObjectTable(Tables.columns(table)))
arraytable(table) = JSON3.write(ArrayTable(Tables.rows(table)))

end # module