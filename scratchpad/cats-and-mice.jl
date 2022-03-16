using MeasureTheory: Iterators
using Tilde
using MeasureTheory

minit = @model begin
    x ~ Poisson(10)
    return (x=x,)
end

mstep = @model p,s begin
    x ~ Poisson(p.a * s.x)
    return (x=x,)
end

m = @model init begin
    a ~ Normal(1,0.1)
    mc ~ Chain(init) do s mstep((a=a,), s) end
    return mc
end

r = rand(m(init=minit()))

x = Iterators.take(r,5) |> collect

###################3

using UnPack


mc_init = @model begin
    🐁 ~ Poisson(100)
    🐈 ~ Poisson(3)
end

mc_step = @model p,s begin
    🐁⬆ ~ Poisson(p.a * s.🐁 * (1 - s.🐁/p.🐁max))
    🐁⬇ ~ Binomial(n=s.🐁, logitp = p.b + p.c * s.🐈)
    🐁 = min(p.🐁max, s.🐁 + 🐁⬆ - 🐁⬇)

    🐈⬆ ~ Poisson(p.d * s.🐈)
    🐈⬇ ~ Binomial(n=s.🐈, logitp = 

    🐈 = s.🐈 + 🐈⬆ - 🐈⬇

    return (🐁 = 🐁, 🐈 = 🐈)
end
