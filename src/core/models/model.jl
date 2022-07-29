struct Model{A,B,M<:GG.TypeLevel} <: AbstractModel{A,B,M}
    args::Vector{Symbol}
    body::Expr
end

function Model(theModule::Module, args::Vector{Symbol}, body::Expr)
    A = NamedTuple{Tuple(args)}
    B = to_type(body)
    M = to_type(theModule)
    return Model{A,B,M}(args, body)
end

model(m::Model) = m
model(::Type{M}) where {M} = type2model(M)

function Base.convert(::Type{Expr}, m::Model)
    numArgs = length(m.args)
    args = if numArgs == 1
        m.args[1]
    elseif numArgs > 1
        Expr(:tuple, [x for x in m.args]...)
    end

    body = m.body

    q = if numArgs == 0
        @q begin
            @model $body
        end
    else
        @q begin
            @model $(args) $body
        end
    end

    striplines(q).args[1]
end

Base.show(io::IO, m::Model) = println(io, convert(Expr, m))

function type2model(::Type{Model{A,B,M}}) where {A,B,M}
    args = Symbol[fieldnames(A)...]
    body = from_type(B)
    Model{A,B,M}(args, body)
end

toargs(vs::Vector{Symbol}) = Tuple(vs)
toargs(vs::NTuple{N,Symbol} where {N}) = vs

macro model(vs::Expr, expr::Expr)
    @assert vs.head == :tuple
    @assert expr.head == :block
    ex = macroexpand(__module__, expr)
    Model(__module__, Vector{Symbol}(vs.args), ex)
end

macro model(v::Symbol, expr::Expr)
    ex = macroexpand(__module__, expr)
    Model(__module__, [v], ex)
end

macro model(expr::Expr)
    ex = macroexpand(__module__, expr)
    Model(__module__, Vector{Symbol}(), ex)
end
