struct ModelClosure{M,V,P} <: AbstractConditionalModel{M,V,NamedTuple{(),Tuple{}},P}
    model::M
    argvals::V
end

function setproj(c::ModelClosure{M,V}, f::F) where {M,V,F}
    setproj(model(c), f)(argvals(c))
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

(m::AbstractModel{A,B,M,P})(nt::NT) where {A,B,M,P,NT<:NamedTuple} = ModelClosure{Model{A,B,M,P}, NT, P}(m,nt)

(mc::ModelClosure)(nt::NamedTuple) = ModelClosure(model(mc), merge(mc.argvals, nt))

argvalstype(mc::ModelClosure{M,A}) where {M,A} = A
argvalstype(::Type{MC}) where {M,A,MC<:ModelClosure{M,A}} = A

obstype(::ModelClosure) = NamedTuple{(),Tuple{}}
obstype(::Type{<:ModelClosure}) = NamedTuple{(),Tuple{}}

type2model(::Type{MC}) where {M,MC<:ModelClosure{M}} = type2model(M)

MeasureBase.condition(m::ModelClosure, nt::NamedTuple) = ModelPosterior(m, nt)
