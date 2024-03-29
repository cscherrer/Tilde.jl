struct ModelPosterior{M,V,O} <: AbstractConditionalModel{M,V,O}
    closure::ModelClosure{M,V}
    obs::O
end

model(post::ModelPosterior) = model(post.closure)

function Base.show(io::IO, cm::ModelPosterior)
    println(io, "ModelPosterior given")
    println(io, "    arguments    ", keys(argvals(cm)))
    println(io, "    observations ", keys(observations(cm)))
    println(io, model(cm))
end

type2model(::Type{MP}) where {M,MP<:ModelPosterior{M}} = type2model(M)
type2model(::ModelPosterior{M}) where {M} = type2model(M)

export argvals
argvals(c::ModelPosterior) = argvals(c.closure)

argvalstype(mp::ModelPosterior{M,A}) where {M,A} = A
argvalstype(::Type{MP}) where {M,A,MP<:ModelPosterior{M,A}} = A

obstype(mp::ModelPosterior{M,A,O}) where {M,A,O} = O
obstype(::Type{MP}) where {M,A,O,MP<:ModelPosterior{M,A,O}} = O

export observations
observations(c::ModelPosterior) = c.obs

export observed
function observed(cm::ModelPosterior{M,A,O}) where {M,A,O}
    keys(schema(O))
end

ModelPosterior(m::AbstractModel) = ModelPosterior(m, NamedTuple(), NamedTuple())

function (post::ModelPosterior)(nt::NamedTuple)
    ModelPosterior(model(post)(mymerge(argvals(post), nt)), post.obs)
end

function Base.:|(post::ModelPosterior, nt::NamedTuple)
    ModelPosterior(post.closure, mymerge(post.obs, nt))
end

function MeasureBase.condition(
    m::MC,
    nt::NT,
) where {M,V,MC<:ModelClosure{M,V},NT<:NamedTuple}
    ModelPosterior{M,V,NT}(m, nt)
end
