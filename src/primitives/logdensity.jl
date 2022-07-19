export logdensityof

using NestedTuples: lazymerge
import MeasureTheory

using Accessors

@inline function MeasureBase.logdensityof(
    cm::AbstractConditionalModel{M,A,O,typeof(first)},
    pars::NamedTuple;
    cfg = NamedTuple(),
    ctx = NamedTuple(),
    retfun = (r, ctx) -> ctx.ℓ,
) where {M,A,O}
    # cfg = merge(cfg, (pars=pars,))
    ctx = merge(ctx, (ℓ = 0.0,))
    runmodel(logdensityof, cm, pars, cfg, ctx, retfun)
end

@inline function tilde(
    cfg::LogdensityofConfig,
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
    cm::AbstractConditionalModel{M,A,O,typeof(first)},
    pars::NamedTuple;
    cfg = NamedTuple(),
    ctx = NamedTuple(),
    retfun = (r, ctx) -> ctx.ℓ,
) where {M,A,O}
    # cfg = merge(cfg, (pars=pars,))
    ctx = merge(ctx, (ℓ = 0.0,))
    runmodel(unsafe_logdensityof, cm, pars, cfg, ctx, retfun)
end

@inline function tilde(
    ::typeof(unsafe_logdensityof),
    x::MaybeObserved{X},
    lens,
    d,
    cfg,
    ctx::NamedTuple,
) where {X}
    x = value(x)
    @reset ctx.ℓ += MeasureBase.unsafe_logdensityof(latentof(d), lens(x))
    (x, ctx)
end