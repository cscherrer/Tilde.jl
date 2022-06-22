using Random: GLOBAL_RNG
using TupleVectors: chainvec

export rand
EmptyNTtype = NamedTuple{(),Tuple{}} where T<:Tuple

@inline function Base.rand(m::ModelClosure, args...; kwargs...) 
    rand(GLOBAL_RNG, Float64, m, args...; kwargs...)
end

@inline function Base.rand(rng::AbstractRNG, m::ModelClosure, args...; kwargs...) 
    rand(rng, Float64, m, args...; kwargs...)
end

@inline function Base.rand(::Type{T_rng}, m::ModelClosure, args...; kwargs...) where {T_rng}
    rand(GLOBAL_RNG, T_rng, m, args...; kwargs...)
end

@inline function Base.rand(m::ModelClosure, d::Integer, dims::Integer...; kwargs...) 
    rand(GLOBAL_RNG, Float64, m, d, dims...; kwargs...)
end

@inline function Base.rand(rng::AbstractRNG, m::ModelClosure, d::Integer, dims::Integer...; kwargs...) 
    rand(rng, Float64, m, d, dims...; kwargs...)
end

@inline function Base.rand(::Type{T_rng}, m::ModelClosure, d::Integer, dims::Integer...; kwargs...) where {T_rng}
    rand(GLOBAL_RNG, T_rng, m, d, dims...; kwargs...)
end

@inline function Base.rand(rng::AbstractRNG, ::Type{T_rng}, d::ModelClosure, N::Integer, v::Vararg{Integer}) where {T_rng}
    @assert isempty(v)
    r = chainvec(rand(rng, T_rng, d), N)
    for j in 2:N
        @inbounds r[j] = rand(rng, T_rng, d)
    end
    return r
end

@inline Base.rand(d::ModelClosure, N::Int) = rand(GLOBAL_RNG, d, N)

@inline function Base.rand(m::ModelClosure; kwargs...) 
    rand(GLOBAL_RNG, m; kwargs...)
end

@inline function Base.rand(rng::AbstractRNG, m::ModelClosure; ctx=NamedTuple(), retfun = (r, ctx) -> r)
    cfg = (rng=rng,)

@inline function Base.rand(rng::AbstractRNG, ::Type{T_rng}, m::ModelClosure; ctx=NamedTuple(), retfun = (r, ctx) -> r) where {T_rng}
    cfg = (rng=rng, T_rng=T_rng)
    gg_call(rand, m, NamedTuple(), cfg, ctx, retfun)
end

###############################################################################
# ctx::NamedTuple
@inline function tilde(::typeof(Base.rand), lens, xname, x, d, cfg, ctx::NamedTuple)
    xnew = set(x.value, Lens!!(lens), rand(cfg.rng, d))
    ctx′ = merge(ctx, NamedTuple{(dynamic(xname),)}((xnew,)))
    (xnew, ctx′, nothing)
end



###############################################################################
# ctx::Dict

@inline function tilde(::typeof(Base.rand), lens::typeof(identity), xname, x, d, cfg, ctx::Dict)
    x = rand(cfg.rng, cfg.T_rng, d)
    ctx[dynamic(xname)] = x 
    (x, ctx, nothing)
end

@inline function tilde(::typeof(Base.rand), lens, xname, x, m::ModelClosure, cfg, ctx::Dict)
    args = get(cfg.args, dynamic(xname), Dict())
    cfg = merge(cfg, (args = args,))
    tilde(rand, lens, xname, x, m(cfg.args), cfg, ctx)
end
