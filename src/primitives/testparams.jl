using TupleVectors: chainvec

export testparams
EmptyNTtype = NamedTuple{(),Tuple{}} where {T<:Tuple}

testparams(d::AbstractMeasure) = testvalue(d)

@inline function testparams(mc::ModelClosure; cfg = NamedTuple(), ctx = NamedTuple())
    gg_call(testparams, mc, NamedTuple(), cfg, ctx, (r, ctx) -> ctx)
end

###############################################################################
# ctx::NamedTuple

@inline function tilde(
    ::typeof(testparams),
    x::MaybeObserved{X},
    lens::typeof(identity),
    d,
    cfg,
    ctx::NamedTuple,
) where {X}
    xnew = testparams(d)
    ctx′ = merge(ctx, NamedTuple{(X,)}((xnew,)))
    (xnew, ctx′, ctx′)
end

@inline function tilde(
    ::typeof(testparams),
    x::MaybeObserved{X},
    lens,
    d,
    cfg,
    ctx::NamedTuple,
) where {X}
    xnew = set(x, Lens!!(lens), testparams(d))
    ctx′ = merge(ctx, NamedTuple{(X,)}((xnew,)))
    (xnew, ctx′, ctx′)
end
