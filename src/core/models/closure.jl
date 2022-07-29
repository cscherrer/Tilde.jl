struct ModelClosure{M,V} <: AbstractConditionalModel{M,V,NamedTuple{(),Tuple{}}}
    model::M
    argvals::V
end


function Base.show(io::IO, mc::ModelClosure)
    println(io, "ModelClosure given")
    println(io, "    arguments    ", keys(argvals(mc)))
    println(io, "    observations ", keys(observations(mc)))
    println(io, model(mc))
end

export argvals
argvals(c::ModelClosure) = c.argvals

export observations
observations(c::ModelClosure) = NamedTuple()

export observed
function observed(mc::ModelClosure{M,A}) where {M,A}
    NamedTuple()
end

model(c::ModelClosure) = c.model

(m::AbstractModel{A,B,M})(nt::NT) where {A,B,M,NT<:NamedTuple} = ModelClosure{Model{A,B,M}, NT}(m,nt)

(mc::ModelClosure)(nt::NamedTuple) = ModelClosure(model(mc), merge(mc.argvals, nt))

argvalstype(mc::ModelClosure{M,A}) where {M,A} = A
argvalstype(::Type{MC}) where {M,A,MC<:ModelClosure{M,A}} = A

obstype(::ModelClosure) = NamedTuple{(),Tuple{}}
obstype(::Type{<:ModelClosure}) = NamedTuple{(),Tuple{}}

type2model(::Type{MC}) where {M,MC<:ModelClosure{M}} = type2model(M)
