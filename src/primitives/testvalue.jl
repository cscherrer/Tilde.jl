using TupleVectors: chainvec
import MeasureTheory: testvalue

export testvalue
EmptyNTtype = NamedTuple{(),Tuple{}} where {T<:Tuple}

@inline function testvalue(
    mc::AbstractConditionalModel;
    cfg = NamedTuple(),
    ctx = NamedTuple(),
)
    runmodel(testvalue, mc, NamedTuple(), cfg, ctx, (r, ctx) -> r)
end

@inline function tilde(
    ::typeof(testvalue),
    x::Unobserved{X},
    lens,
    d,
    cfg,
    ctx::NamedTuple,
) where {X}
    xnew = set(value(x), Lens!!(lens), testvalue(d))
    ctx′ = merge(ctx, NamedTuple{(X,)}((xnew,)))
    (xnew, ctx′)
end

@inline function tilde(
    ::typeof(testvalue),
    x::Observed{X},
    lens,
    d,
    cfg,
    ctx::NamedTuple,
) where {X}
    (lens(value(x)), ctx)
end
