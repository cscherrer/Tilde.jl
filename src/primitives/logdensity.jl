
export logdensityof

using NestedTuples: lazymerge
import MeasureTheory

using Accessors


@inline function MeasureBase.logdensityof(cm::AbstractConditionalModel, pars::NamedTuple; cfg=NamedTuple(), ctx=NamedTuple(), retfun=(r,ctx) -> ctx.ℓ)
    # cfg = merge(cfg, (pars=pars,))
    ctx = merge(ctx, (ℓ = 0.0,))
    gg_call(logdensityof, cm, pars, cfg, ctx, retfun)
end

@inline function tilde(::typeof(logdensityof), x::MaybeObserved{X}, lens, d, cfg, ctx::NamedTuple) where {X}
    x = value(x)
    insupport(d, lens(x)) || return (x, ctx, ReturnNow(-Inf))
    @reset ctx.ℓ += MeasureBase.unsafe_logdensityof(d, lens(x))
    (x, ctx, nothing)
end

@inline function MeasureBase.unsafe_logdensityof(cm::AbstractConditionalModel, pars::NamedTuple; cfg=NamedTuple(), ctx=NamedTuple(), retfun=(r,ctx) -> ctx.ℓ)
    # cfg = merge(cfg, (pars=pars,))
    ctx = merge(ctx, (ℓ = 0.0,))
    gg_call(unsafe_logdensityof, cm, pars, cfg, ctx, retfun)
end

@inline function tilde(::typeof(unsafe_logdensityof), lens, xname, x, d, cfg, ctx::NamedTuple)
    x = value(x)
    @reset ctx.ℓ += MeasureBase.unsafe_logdensityof(d, lens(x))
    (x, ctx, ctx.ℓ)
end
