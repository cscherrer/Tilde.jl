using TupleVectors: chainvec
import MeasureTheory: testvalue

struct TestValueConfig <: AbstractConfig
end

@inline retfun(cfg::TestValueConfig, r, ctx) = r


export testvalue
EmptyNTtype = NamedTuple{(),Tuple{}} where {T<:Tuple}

@inline function testvalue(mc::AbstractConditionalModel)
    cfg = TestValueConfig()
    ctx = NamedTuple()
    runmodel(cfg, mc, NamedTuple(), ctx)
end

@inline function tilde(
    ::TestValueConfig,
    x::Unobserved{X},
    lens,
    d,
    ctx::NamedTuple,
) where {X}
    xnew = set(value(x), Lens!!(lens), testvalue(d))
    ctx′ = merge(ctx, NamedTuple{(X,)}((xnew,)))
    (xnew, ctx′)
end

@inline function tilde(
    ::TestValueConfig,
    x::Observed{X},
    lens,
    d,
    ctx::NamedTuple,
) where {X}
    (lens(value(x)), ctx)
end
