using TupleVectors: chainvec
import MeasureTheory: testvalue

# Just a temporary quick fix
testvalue(m::AbstractConditionalModel) = _rand(FixedRNG(), m)

# struct TestValueConfig <: AbstractConfig
# end

# @inline retfun(cfg::TestValueConfig, r, ctx) = r


# export testvalue
# EmptyNTtype = NamedTuple{(),Tuple{}} where {T<:Tuple}

# @inline function testvalue(mc::AbstractConditionalModel)
#     cfg = TestValueConfig()
#     ctx = NamedTuple()
#     runmodel(cfg, mc, NamedTuple(), ctx)
# end

# @inline function tilde(
#     ::TestValueConfig,
#     z_obs::Unobserved{Z},
#     lens,
#     d,
#     ctx::NamedTuple,
# ) where {Z}
#     z = value(z_obs)
#     zj = testvalue(d)
#     @show d
#     @show zj
#     new_z = set(z, Lens!!(lens), zj)
#     ctx′ = merge(ctx, NamedTuple{(Z,)}((new_z,)))
#     xj = predict(rng, d, zj)
#     (xj, ctx′)
# end

# @inline function tilde(
#     ::TestValueConfig,
#     z_obs::Observed{Z},
#     lens,
#     d,
#     ctx::NamedTuple,
# ) where {Z}
#     z = value(z_obs)
#     zj = lens(z)
#     xj = predict(rng, d, zj)
#     (xj, ctx)
# end
