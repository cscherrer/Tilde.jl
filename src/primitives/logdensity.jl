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
    pars::NamedTuple;
) where {M,A,O}
    cfg = LogdensityConfig(logdensityof)
    runmodel(cfg, cm, pars, (ℓ=0,))
end

@inline function tilde(
    cfg::LogdensityConfig{typeof(logdensityof)},
    x::MaybeObserved{X},
    lens,
    d,
    ctx::NamedTuple,
) where {X}
    x = value(x)
    # insupport(d, lens(x)) || return (x, ReturnNow(-Inf))
    pred = predict(d, lens(x))
    @reset ctx.ℓ += logdensityof(d, lens(x))
    (pred, ctx)
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
    x::MaybeObserved{X},
    lens,
    d,
    ctx::NamedTuple,
) where {X}
    x = value(x)
    # insupport(d, lens(x)) || return (x, ReturnNow(-Inf))
    pred = predict(d, lens(x))
    @reset ctx.ℓ += unsafe_logdensityof(d, lens(x))
    (pred, ctx)
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
    x::MaybeObserved{X},
    lens,
    d,
    ctx::NamedTuple,
) where {X}
    x = value(x)
    # insupport(d, lens(x)) || return (x, ReturnNow(-Inf))
    pred = predict(d, lens(x))
    @reset ctx.ℓ += logdensity_def(d, lens(x))
    (pred, ctx)
end
