using Random: GLOBAL_RNG
using TupleVectors
export predict

@inline function predict(m::AbstractConditionalModel, pars)
    return predict(GLOBAL_RNG, m, pars)
end

@inline function predict(rng::AbstractRNG, m::AbstractConditionalModel, pars::NamedTuple; ctx=NamedTuple())
    cfg = (rng=rng, pars=pars)
    ctx = NamedTuple()
    gg_call(predict, m, pars, cfg, ctx, (r, ctx) -> r)
end

@inline function predict(rng::AbstractRNG, m::AbstractConditionalModel, tv::TupleVector; ctx=NamedTuple())
    n = length(tv)
    result = chainvec(predict(rng, m, tv[1]), n)
    for j in 2:n
        result[j] = predict(rng, m, tv[1])
    end
    return result
end

@inline function tilde(::typeof(predict), lens, xname, x, d, cfg, ctx)
    tilde_predict(cfg.rng, lens, xname, x, d, cfg.pars, ctx)
end

@generated function tilde_predict(rng, lens, ::StaticSymbol{X}, x, d, pars::NamedTuple{N}, ctx) where {X,N}
    if X ∈ N
        quote
            # @info "$X ∈ N"
            xnew = set(x.value, Lens!!(lens), lens(getproperty(pars, X)))
            # ctx = merge(ctx, NamedTuple{(X,)}((xnew,)))
            (xnew, ctx, ctx)
        end
    else
        quote
            # @info "$X ∉ N"
            xnew = set(x.value, Lens!!(lens), rand(rng, d))
            ctx = merge(ctx, NamedTuple{(X,)}((xnew,)))
            (xnew, ctx, ctx)
        end
    end
end

