# export measures!

# """
#     measures!(meas, m::AbstractConditionalModel, pars)

# Traverse the model `m` using parameters `pars`, saving measures in `meas`.
# `meas` must have the same structure as `rand(m)`.

# EXAMPLE

#     julia> m = @model x begin
#         x[1] ~ Normal()
#         for j in 2:length(x)
#             x[j] ~ Normal(μ = x[j-1])
#         end
#     end;

#     julia> x = zeros(10);

#     julia> r = rand(m(x))
#     (x = [0.0278136, -2.08267, -3.52533, -3.88132, -3.60991, -4.90486, -4.81384, -5.05961, -3.75905, -3.42328],)

#     julia> meas = (x=Vector{Any}(undef, 10),) # similar to `r`
#     (x = Any[#undef, #undef, #undef, #undef, #undef, #undef, #undef, #undef, #undef, #undef],)

#     julia> measures!(meas, m(x), r)
#     (x = Any[Normal(), Normal(μ = 0.0278136,), Normal(μ = -2.08267,), Normal(μ = -3.52533,), 
#     Normal(μ = -3.88132,), Normal(μ = -3.60991,), Normal(μ = -4.90486,), Normal(μ = -4.81384,), 
#     Normal(μ = -5.05961,), Normal(μ = -3.75905,)],)

#     julia> meas.x
#     10-element Vector{Any}:
#      Normal()
#      Normal(μ = 0.0278136,)
#      Normal(μ = -2.08267,)
#      Normal(μ = -3.52533,)
#      Normal(μ = -3.88132,)
#      Normal(μ = -3.60991,)
#      Normal(μ = -4.90486,)
#      Normal(μ = -4.81384,)
#      Normal(μ = -5.05961,)
#      Normal(μ = -3.75905,)
# """

struct MeasuresConfig{P} <: AbstractTildeConfig
    pars::P
end

@inline retfun(cfg::MeasuresConfig, r, ctx) = ctx


export measures

@inline function measures(m::AbstractConditionalModel, pars::NamedTuple{N,T}) where {N,T}
    function sim(x::AbstractArray)
        new_x = similar(x, Any)
        new_x .= x
    end
    sim(x) = x

    cfg=  MeasuresConfig(pars)
    ctx = rmap(sim, pars)

    nt = runmodel(cfg, latentof(m), pars, ctx)

    f(x::AbstractArray) = productmeasure(narrow_array(x))
    f(x) = x

    rmap(f, nt)
end

@inline function tilde(cfg::MeasuresConfig, x::Unobserved{X}, d, ctx) where {X}
    x = rand(FixedRNG(), d)
    ctx = merge(ctx, NamedTuple{X}((d,)))
    (x, ctx)
end

@inline function tilde(cfg::MeasuresConfig, x::Unobserved{X}, lens, d, ctx) where {X}
    ctx = set(ctx, PropertyLens{X}() ⨟ Lens!!(lens), d)

    xnew = getproperty(cfg.pars, X)
    (xnew, ctx)
end

@inline function tilde(cfg::MeasuresConfig, x::Observed{X}, lens, d, ctx) where {X}
    (value(x), ctx)
end

function as(mdl::AbstractConditionalModel)
    ms = measures(mdl)
    as(map(as, ms))
end

measures(m) = measures(m, rand(FixedRNG(), m))
