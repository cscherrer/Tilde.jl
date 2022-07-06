using Random: GLOBAL_RNG
using TupleVectors
export predict


anyfy(x) = x
anyfy(x::AbstractArray) = collect(Any, x)

function anyfy(mc::ModelClosure)
    m = model(mc)
    a = rmap(anyfy, argvals(mc))
    m(a)
end

function anyfy(mp::ModelPosterior)
    m = model(mp)
    a = rmap(anyfy, argvals(mp))
    o = rmap(anyfy, observations(mp))
    m(a) | o
end

@inline function predict(m::AbstractConditionalModel, pars)
    f(d, x) = rand(GLOBAL_RNG, d)
    return predict(f, m, pars)
end

@inline function predict(rng::AbstractRNG, m::AbstractConditionalModel, pars)
    f(d, x) = rand(rng, d)
    return predict(f, m, pars)
end

@inline function predict(f, m::AbstractConditionalModel, pars::NamedTuple)
    m = anyfy(m)
    pars = rmap(anyfy, pars) 
    cfg = (f = f, pars = pars)
    ctx = NamedTuple()
    gg_call(predict, m, pars, cfg, ctx, (r, ctx) -> r)
end

@inline function predict(f, m::AbstractConditionalModel, tv::TupleVector)
    n = length(tv)
    @inbounds result = chainvec(predict(f, m, tv[1]), n)
    @inbounds for j in 2:n
        result[j] = predict(f, m, tv[j])
    end
    return result
end

@inline function tilde(::typeof(predict), x, lens, d, cfg, ctx)
    tilde_predict(cfg.f, x, lens, d, cfg.pars, ctx)
end

@generated function tilde_predict(
    f,
    x::Observed{X},
    lens,
    d,
    pars::NamedTuple{N},
    ctx,
) where {X,N}
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
            x = x.value
            xnew = set(copy(x), Lens!!(lens), f(d, lens(x)))
            ctx = merge(ctx, NamedTuple{(X,)}((xnew,)))
            (xnew, ctx, ctx)
        end
    end
end

@generated function tilde_predict(
    f,
    x::Unobserved{X},
    lens,
    d,
    pars::NamedTuple{N},
    ctx,
) where {X,N}
    if X ∈ N
        quote
            # @info "$X ∈ N"
            xnew = set(value(x), Lens!!(lens), lens(getproperty(pars, X)))
            # ctx = merge(ctx, NamedTuple{(X,)}((xnew,)))
            (xnew, ctx, ctx)
        end
    else
        quote
            # @info "$X ∉ N"
            # In this case x == Unobserved(missing)
            xnew = set(value(x), Lens!!(lens), f(d, missing))
            ctx = merge(ctx, NamedTuple{(X,)}((xnew,)))
            (xnew, ctx, ctx)
        end
    end
end
