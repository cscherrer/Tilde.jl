export logdensityof

using NestedTuples: lazymerge
import MeasureTheory

using Accessors

struct LogdensityConfig{F} <: AbstractConfig
    f::F
end

@inline retfun(cfg::LogdensityConfig{typeof(logdensityof)}, r, ctx) = ctx.ℓ
@inline retfun(cfg::LogdensityConfig{typeof(unsafe_logdensityof)}, r, ctx) = ctx.ℓ


@inline function MeasureBase.logdensityof(
    cm::AbstractConditionalModel{M,A,O},
    pars::NamedTuple;
) where {M,A,O}
    # cfg = merge(cfg, (pars=pars,))
    cfg = LogdensityConfig(logdensityof)
    runmodel(cfg, cm, pars, (ℓ=0.0,))
end

@inline function tilde(
    cfg::LogdensityConfig{typeof(logdensityof)},
    x::MaybeObserved{X},
    lens,
    d,
    ctx::NamedTuple,
) where {X}
    x = value(x)
    insupport(d, lens(x)) || return (x, ctx, ReturnNow(-Inf))
    @reset ctx.ℓ += MeasureBase.unsafe_logdensityof(d, lens(x))
    (x, ctx)
end

@inline function MeasureBase.unsafe_logdensityof(
    cm::AbstractConditionalModel{M,A,O},
    pars::NamedTuple;
) where {M,A,O}
    cfg = LogdensityConfig(unsafe_logdensityof)
    runmodel(cfg, cm, pars, (ℓ = 0.0,))
end

@inline function tilde(
    cfg::LogdensityConfig{typeof(unsafe_logdensityof)},
    x::MaybeObserved{X},
    lens,
    d,
    ctx::NamedTuple,
) where {X}
    x = value(x)
    @reset ctx.ℓ += MeasureBase.unsafe_logdensityof(d, lens(x))
    (x, ctx)
end
