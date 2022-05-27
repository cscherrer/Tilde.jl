export measures!

"""
    measures!(meas, m::AbstractConditionalModel, pars)

Traverse the model `m` using parameters `pars`, saving measures in `meas`.
`meas` must have the same structure as `rand(m)`.

EXAMPLE

    julia> m = @model x begin
        x[1] ~ Normal()
        for j in 2:length(x)
            x[j] ~ Normal(μ = x[j-1])
        end
    end;

    julia> x = zeros(10);

    julia> r = rand(m(x))
    (x = [0.0278136, -2.08267, -3.52533, -3.88132, -3.60991, -4.90486, -4.81384, -5.05961, -3.75905, -3.42328],)

    julia> meas = (x=Vector{Any}(undef, 10),) # similar to `r`
    (x = Any[#undef, #undef, #undef, #undef, #undef, #undef, #undef, #undef, #undef, #undef],)

    julia> measures!(meas, m(x), r)
    (x = Any[Normal(), Normal(μ = 0.0278136,), Normal(μ = -2.08267,), Normal(μ = -3.52533,), 
    Normal(μ = -3.88132,), Normal(μ = -3.60991,), Normal(μ = -4.90486,), Normal(μ = -4.81384,), 
    Normal(μ = -5.05961,), Normal(μ = -3.75905,)],)

    julia> meas.x
    10-element Vector{Any}:
     Normal()
     Normal(μ = 0.0278136,)
     Normal(μ = -2.08267,)
     Normal(μ = -3.52533,)
     Normal(μ = -3.88132,)
     Normal(μ = -3.60991,)
     Normal(μ = -4.90486,)
     Normal(μ = -4.81384,)
     Normal(μ = -5.05961,)
     Normal(μ = -3.75905,)
"""
@inline function measures!(meas, m::AbstractConditionalModel, pars)
    ctx = meas
    gg_call(measures!, m, pars, NamedTuple(), ctx, (r, ctx) -> ctx)
end

@inline function tilde(::typeof(measures!), lens, xname, x::Unobserved, d, cfg, ctx)
    x = x.value
    xname = dynamic(xname)
    l = PropertyLens{xname}() ⨟ Lens!!(lens)
    ctx = set(ctx, l, d)
    (x, ctx, ctx)
end

@inline function tilde(::typeof(measures!), lens, xname, x::Observed, d, cfg, ctx)
    x = x.value
    (x, ctx, ctx)
end

export measures

function measures(m::AbstractConditionalModel, pars)
    sim(x::AbstractArray) = similar(x, Any)
    sim(x) = x

    f(x::AbstractArray) = productmeasure(narrow_array(x))
    f(x) = x

    rmap(f, measures!(rmap(sim, pars), m, pars))
end

measures(m::AbstractConditionalModel) = measures(m, testvalue(m))

function as(mdl::AbstractConditionalModel)
    ms = measures(mdl)
    as(map(as, ms))
end