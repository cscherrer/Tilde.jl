using TupleVectors: chainvec
import MeasureTheory: testvalue

export testvalue
EmptyNTtype = NamedTuple{(),Tuple{}} where {T<:Tuple}

@inline function testvalue(
    mc::AbstractConditionalModel;
    cfg = NamedTuple(),
    ctx = NamedTuple(),
)
    gg_call(testvalue, mc, NamedTuple(), cfg, ctx, (r, ctx) -> r)
end

@inline function tilde(
    ::typeof(testvalue),
    lens,
    xname,
    x::Unobserved,
    d,
    cfg,
    ctx::NamedTuple,
)
    xnew = set(x.value, Lens!!(lens), testvalue(d))
    ctx′ = merge(ctx, NamedTuple{(dynamic(xname),)}((xnew,)))
    (xnew, ctx′, nothing)
end

@inline function tilde(
    ::typeof(testvalue),
    lens,
    xname,
    x::Observed,
    d,
    cfg,
    ctx::NamedTuple,
)
    (x.value, ctx, nothing)
end
