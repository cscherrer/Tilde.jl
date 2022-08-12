using Random: GLOBAL_RNG, AbstractRNG
using TupleVectors
export predict

struct PredictConfig{T_rng, RNG,P} <: AbstractConfig
    rng::RNG
    pars::P
    PredictConfig(::Type{T_rng}, rng::RNG, pars::P) where {T_rng, RNG<:AbstractRNG,P} = new{T_rng,RNG,P}(rng,pars)
end

PredictConfig(::Type{T_rng}, rng::AbstractRNG) where {T_rng} = PredictConfig(T_rng, rng, NamedTuple())
PredictConfig(::Type{T_rng}, pars) where {T_rng} = PredictConfig(T_rng, GLOBAL_RNG, pars)
PredictConfig(rng::AbstractRNG, pars)  = PredictConfig(Float64, rng, pars)

PredictConfig(::Type{T_rng}) where {T_rng} = PredictConfig(T_rng, GLOBAL_RNG, NamedTuple())
PredictConfig(rng::AbstractRNG) = PredictConfig(Float64, rng, NamedTuple())
PredictConfig(pars) = PredictConfig(Float64, GLOBAL_RNG, pars)

PredictConfig() = PredictConfig(Float64, GLOBAL_RNG, NamedTuple())

retfun(::PredictConfig, r, ctx) = r


anyfy(x) = x
anyfy(x::AbstractArray) = collect(Any, x)

function anyfy(mc::ModelClosure)
    m = model(mc)
    a = rmap(anyfy, argvals(mc))
    m(a)
end

function anyfy(mp::ModelPosterior)
    m = model(mp)
    a = rmap(anyfy, argvals(mp))
    o = rmap(anyfy, observations(mp))
    m(a) | o
end

###############################################################################
# `predict` for forward random sampling

predict(d::AbstractMeasure, pars) = pars

@inline function predict(rng::AbstractRNG, m::AbstractConditionalModel, pars::NamedTuple)
    predict_rand(rng::AbstractRNG, m::AbstractConditionalModel, pars)
end

@inline function predict_rand(rng::AbstractRNG, m::AbstractConditionalModel, pars)
    cfg = PredictConfig(rng, pars)
    ctx = NamedTuple()
    runmodel(cfg, m, pars, ctx)
end


@inline function tilde(cfg::PredictConfig, x, lens, d, ctx)
    tilde_predict(cfg.rng, x, lens, d, cfg.pars, ctx)
end



@generated function tilde_predict(
    rng,
    z_obs::MaybeObserved{Z},
    lens,
    d,
    pars::NamedTuple{N},
    ctx,
) where {Z,N}
    if Z ∈ N
        quote
            # @info "$X ∈ N"
            z = value(z_obs)
            zj = lens(z)
            xj = predict(d, zj)
            xnew = set(z, Lens!!(lens), lens(getproperty(pars, Z)))
            # ctx = merge(ctx, NamedTuple{(X,)}((xnew,)))
            (xj, ctx)
        end
    else
        quote
            # @info "$X ∉ N"
            z = value(z_obs)
            zj = predict(rng, d)
            new_z = set(z, Lens!!(lens), zj)
            xj = predict(d, zj)
            ctx = merge(ctx, NamedTuple{(Z,)}((new_z,)))
            (xj, ctx)
        end
    end
end


###############################################################################



@inline function predict(f, m::AbstractConditionalModel, pars::NamedTuple)
    m = anyfy(m)
    pars = rmap(anyfy, pars) 
    cfg = (f = f, pars = pars)
    ctx = NamedTuple()
    runmodel(predict, m, pars, cfg, ctx, (r, ctx) -> r)
end

@inline function predict(f, m::AbstractConditionalModel, tv::TupleVector)
    n = length(tv)
    @inbounds result = chainvec(predict(f, m, tv[1]), n)
    @inbounds for j in 2:n
        result[j] = predict(f, m, tv[j])
    end
    return result
end

@inline function tilde(::typeof(predict), x, lens, d, cfg, ctx)
    tilde_predict(cfg.f, x, lens, d, cfg.pars, ctx)
end

# @generated function tilde_predict(
#     f,
#     z::Observed{Z},
#     lens,
#     d,
#     pars::NamedTuple{N},
#     ctx,
# ) where {Z,N}
#     if X ∈ N
#         quote
#             # @info "$X ∈ N"
#             xnew = set(x.value, Lens!!(lens), lens(getproperty(pars, X)))
#             # ctx = merge(ctx, NamedTuple{(X,)}((xnew,)))
#             (xnew, ctx, ctx)
#         end
#     else
#         quote
#             # @info "$X ∉ N"
#             x = x.value
#             xnew = set(copy(x), Lens!!(lens), f(d, lens(x)))
#             ctx = merge(ctx, NamedTuple{(X,)}((xnew,)))
#             (xnew, ctx, ctx)
#         end
#     end
# end

# @generated function tilde_predict(
#     f,
#     z::Unobserved{Z},
#     lens,
#     d,
#     pars::NamedTuple{N},
#     ctx,
# ) where {Z,N}
#     if X ∈ N
#         quote
#             # @info "$X ∈ N"
#             xnew = set(value(x), Lens!!(lens), lens(getproperty(pars, X)))
#             # ctx = merge(ctx, NamedTuple{(X,)}((xnew,)))
#             (xnew, ctx, ctx)
#         end
#     else
#         quote
#             # @info "$X ∉ N"
#             # In this case x == Unobserved(missing)
#             xnew = set(value(x), Lens!!(lens), f(d, missing))
#             ctx = merge(ctx, NamedTuple{(X,)}((xnew,)))
#             (xnew, ctx, ctx)
#         end
#     end
# end



###############################################################################
# Dispatch helpers


@inline function predict(rng::AbstractRNG, m::ModelPosterior, pars::NamedTuple)
    predict_rand(rng, m.closure, pars)
end


@inline function predict(m::AbstractConditionalModel, pars)
    predict(GLOBAL_RNG, m, pars)
end


@inline function predict(m::AbstractConditionalModel)
    predict(GLOBAL_RNG, m, NamedTuple())
end

@inline function predict(rng::AbstractRNG, m::AbstractConditionalModel)
    predict_rand(rng, m, NamedTuple())
end

function predict(args...)
    rand(args...)
end

