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



export dag





using Graphs
using MetaGraphsNext



struct MarkovContext{T,M} <: AbstractContext
    value::T
    meta::M
end

function markovinate(nt::NamedTuple{N,T}) where {N,T}
    vals = tuple((MarkovContext(v, Set((k,identity))) for (k,v) in pairs(nt))...)
    NamedTuple{N}(vals)
end

MarkovContext(x::MarkovContext) = x
MarkovContext(x) = MarkovContext(x, Set())

markov_parents(x) = Set()

markov_value(x::MarkovContext) = x.value
markov_parents(x::MarkovContext) = x.meta

function dag(m::AbstractConditionalModel, pars)
    cfg = NamedTuple()
    pars = markovinate(pars)
    dag = MetaGraph(DiGraph(), Label = Tuple{Symbol, Any})
    ctx =  (dag = dag,)
    gg_call(dag, m, pars, cfg, ctx, (r, ctx) -> ctx)
end

# When a Tilde primitive `f` is called, every `g(args...)` is converted to
# `call(f, g, args...)` 
function call(::typeof(dag), g, args...; kwargs...)
    val = g(map(markov_value, args)...; map(markov_value, kwargs)...)
    parents = union(map(markov_parents, args)..., map(ctx_meta, kwargs)...)
    MarkovContext(val, parents)
end

@inline function tilde(::typeof(dag), x::MaybeObserved{X}, lens, d, pars, ctx) where {X}
    for p in markov_parents(d)
        # Add a new edge in the DAG
        ctx.dag[p, Set(((X, lens),))] = nothing
    end
    (MarkovContext(x, (X, lens)), ctx, ctx.dag)
end

