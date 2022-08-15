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

export getdag

using Graphs
using MetaGraphsNext

struct MarkovContext{T} <: AbstractContext
    value::T
    meta::Set{Tuple{Symbol,Any}}
end

function MarkovContext(ctx::MarkovContext, m::Set{Tuple{Symbol,Any}})
    newset = union(ctx.meta, m)
    MarkovContext(ctx.value, newset)
end

function MarkovContext(ctx::MarkovContext, m::Set{Tuple{Symbol,T}}) where {T}
    newset = union(ctx.meta, Set{Tuple{Symbol,Any}}([m]))
    MarkovContext(ctx.value, newset)
end

function Base.show(io::IO, mc::MarkovContext)
    print(io, "MarkovContext(", mc.value, ", ", mc.meta, ")")
end

function markovinate(nt::NamedTuple{N,T}) where {N,T}
    vals = tuple(
        (
            MarkovContext(v, Set{Tuple{Symbol,Any}}([(k, identity)])) for
            (k, v) in pairs(nt)
        )...,
    )
    NamedTuple{N}(vals)
end

MarkovContext(x::MarkovContext) = x
MarkovContext(x) = MarkovContext(x, Set{Tuple{Symbol,Any}}())

markov_value(x) = x
markov_parents(x) = Set{Tuple{Symbol,Any}}()

markov_value(x::MarkovContext) = x.value
markov_parents(x::MarkovContext) = x.meta

function getdag(m::AbstractConditionalModel, pars)
    cfg = NamedTuple()
    pars = markovinate(pars)
    ctx = (dag = MetaGraph(DiGraph(), Label = Tuple{Symbol,Any}),)
    ctx = runmodel(getdag, m, pars, cfg, ctx, (r, ctx) -> ctx)
    return ctx.dag
end

# When a Tilde primitive `f` is called, every `g(args...)` is converted to
# `call(f, g, args...)` 
function call(::typeof(getdag), g, args...)
    val = g(map(markov_value, args)...)
    parents = if isempty(args)
        Set{Tuple{Symbol,Any}}()
    else
        union(map(markov_parents, args)...)
    end
    MarkovContext(val, parents)
end

@inline function tilde(::typeof(getdag), x::MaybeObserved{Z}, lens, d, pars, ctx) where {Z}
    dag = ctx.dag
    for p in markov_parents(d)
        # Make sure vertices exist
        dag[p] = nothing
        dag[(X, lens)] = nothing
        # Add a new edge in the DAG
        dag[p, (X, lens)] = nothing
    end
    (MarkovContext(value(x), Set{Tuple{Symbol,Any}}([(X, lens)])), ctx, dag)
end
