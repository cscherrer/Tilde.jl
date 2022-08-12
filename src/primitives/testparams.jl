using TupleVectors: chainvec

export testparams
EmptyNTtype = NamedTuple{(),Tuple{}} where {T<:Tuple}

testparams(d::AbstractMeasure) = testvalue(d)

@inline function testparams(mc::ModelClosure; cfg = NamedTuple(), ctx = NamedTuple())
    runmodel(testparams, mc, NamedTuple(), cfg, ctx, (r, ctx) -> ctx)
end

###############################################################################
# ctx::NamedTuple

@inline function tilde(
    ::typeof(testparams),
    x::MaybeObserved{Z},
    lens::typeof(identity),
    d,
    cfg,
    ctx::NamedTuple,
) where {Z}
    xnew = testparams(d)
    ctx′ = merge(ctx, NamedTuple{(X,)}((xnew,)))
    (xnew, ctx′)
end

@inline function tilde(
    ::typeof(testparams),
    x::MaybeObserved{Z},
    lens,
    d,
    cfg,
    ctx::NamedTuple,
) where {Z}
    xnew = set(x, Lens!!(lens), testparams(d))
    ctx′ = merge(ctx, NamedTuple{(X,)}((xnew,)))
    (xnew, ctx′)
end
