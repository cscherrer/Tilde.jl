export logdensityof

using NestedTuples: lazymerge
import MeasureTheory

using Accessors

struct LogdensityConfig{F} <: AbstractConfig
    f::F
end

@inline retfun(cfg::LogdensityConfig{typeof(logdensityof)}, r, ctx) = ctx.ℓ
@inline retfun(cfg::LogdensityConfig{typeof(unsafe_logdensityof)}, r, ctx) = ctx.ℓ
@inline retfun(cfg::LogdensityConfig{typeof(logdensity_def)}, r, ctx) = ctx.ℓ

@inline function MeasureBase.logdensityof(
    cm::AbstractConditionalModel{M,A,O},
    pars::NamedTuple{N,T};
) where {M,A,O,N,T}
    cfg = LogdensityConfig(logdensityof)
    runmodel(cfg, cm, pars, (ℓ=0,))
end

@inline function tilde(
    cfg::LogdensityConfig{typeof(logdensityof)},
    z_obs::MaybeObserved{Z},
    lens,
    d,
    ctx::NamedTuple,
) where {Z}
    z = value(z_obs)
    zj = lens(z)
    # insupport(d, lens(x)) || return (x, ReturnNow(-Inf))
    xj = predict(d, zj)
    @reset ctx.ℓ += logdensityof(d, zj)
    (xj, ctx)
end

@inline function MeasureBase.unsafe_logdensityof(
    cm::AbstractConditionalModel{M,A,O},
    pars::NamedTuple;
) where {M,A,O}
    cfg = LogdensityConfig(unsafe_logdensityof)
    runmodel(cfg, cm, pars, (ℓ = 0,))
end

@inline function tilde(
    cfg::LogdensityConfig{typeof(unsafe_logdensityof)},
    z_obs::MaybeObserved{Z},
    lens,
    d,
    ctx::NamedTuple,
) where {Z}
    z = value(z_obs)
    zj = lens(z)
    xj = predict(d, zj)
    # insupport(d, lens(x)) || return (x, ReturnNow(-Inf))
    @reset ctx.ℓ += unsafe_logdensityof(d, zj)
    (xj, ctx)
end


@inline function MeasureBase.logdensity_def(
    cm::AbstractConditionalModel{M,A,O},
    pars::NamedTuple;
) where {M,A,O}
    cfg = LogdensityConfig(logdensity_def)
    runmodel(cfg, cm, pars, (ℓ = 0.0,))
end

@inline function tilde(
    cfg::LogdensityConfig{typeof(logdensity_def)},
    z_obs::MaybeObserved{Z},
    lens,
    d,
    ctx::NamedTuple,
) where {Z}
    z = value(z_obs)
    zj = lens(z)
    xj = predict(d, zj)
    # insupport(d, lens(x)) || return (x, ReturnNow(-Inf))
    pred = predict(d, zj)
    @reset ctx.ℓ += logdensity_def(d, zj)
    (xj, ctx)
end
