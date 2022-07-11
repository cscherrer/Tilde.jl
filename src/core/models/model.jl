struct Model{A,B,M<:GG.TypeLevel,P} <: AbstractModel{A,B,M,P}
    args::Vector{Symbol}
    body::Expr
    jointproj::P
end

function Model(theModule::Module, args::Vector{Symbol}, body::Expr)
    A = NamedTuple{Tuple(args)}
    B = to_type(body)
    M = to_type(theModule)
    return Model{A,B,M,typeof(last)}(args, body, last)
end

export latentof, manifestof, jointof

setproj(m::Model{A,B,M}, f::F) where {A,B,M,F} = Model{A,B,M,F}(m.args, m.body, f)

latentof(m) = setproj(m, first)
manifestof(m) = setproj(m, last)
jointof(m) = setproj(m, identity)

model(m::Model) = m

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

function type2model(::Type{Model{A,B,M,P}}) where {A,B,M,P}
    args = Symbol[fieldnames(A)...]
    body = from_type(B)
    jointproj = P.instance
    Model{A,B,M,P}(args, body, jointproj)
end

toargs(vs::Vector{Symbol}) = Tuple(vs)
toargs(vs::NTuple{N,Symbol} where {N}) = vs

macro model(vs::Expr, expr::Expr)
    theModule = __module__
    @assert vs.head == :tuple
    @assert expr.head == :block
    Model(theModule, Vector{Symbol}(vs.args), expr)
end

macro model(v::Symbol, expr::Expr)
    theModule = __module__
    Model(theModule, [v], expr)
end

macro model(expr::Expr)
    theModule = __module__
    Model(theModule, Vector{Symbol}(), expr)
end
