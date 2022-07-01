abstract type AbstractContext end

struct GenericContext{T,M} <: AbstractContext
    value::T
    meta::M
end

struct EmptyMeta end

context(value, meta) = GenericContext(value, meta)
context(value) = GenericContext(value, EmptyMeta())

context_value(ctx::AbstractContext) = ctx.value
context_meta(ctx::AbstractContext) = ctx.meta














struct MarkovContext{T,M} <: AbstractContext
    value::T
    meta::M
end

MarkovContext(x::MarkovContext) = x
MarkovContext(x) = MarkovContext(x, Set())

markov_parents(x) = Set()

markov_value(x::MarkovContext) = x.value
markov_parents(x::MarkovContext) = x.parents

# When a Tilde primitive `f` is called, every `g(args...)` is converted to
# `call(f, g, args...)` 
function call(::typeof(dag), g, args...)
    val = g(map(markov_value, args)...; map(markov_value, kwargs)...)
    parents = union(map(markov_parents, args)..., map(ctx_meta, kwargs)...)
    MarkovContext(val, parents)
end

function dag(m::AbstractConditionalModel, pars)
    ctx =  SimpleDigraph()
    gg_call(dag, m, pars, cfg, ctx, (r, ctx) -> ctx)
end

@inline function tilde(::typeof(dag), lens, xname, x, d, pars, ctx::MetaDiGraph)
    xnew = set(x.value, Lens!!(lens), rand(cfg.rng, d))
    ctx′ = merge(ctx, NamedTuple{(dynamic(xname),)}((xnew,)))
    (xnew, ctx′, nothing)
end


@inline function tilde(::typeof(unsafe_logdensityof), lens, xname, x, d, cfg, ctx::NamedTuple)
    x = x.value
    for p in markov_parents(d)
        # Add a new edge in the DAG
        ctx.dag[(dynamic(xname), lens), p] = nothing
    end
    (MarkovContext(x), ctx, ctx.dag)
end
