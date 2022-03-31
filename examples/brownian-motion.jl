using MeasureTheory
using Random
using LinearAlgebra
using Test
import MeasureBase: logdensity_def, logdensity_rel, basemeasure, insupport
PLOT = false
struct BrownianMotion <: AbstractMeasure
    num_terms::Int
end

Base.rand(rng::Random.AbstractRNG, ::Type{T}, bm::BrownianMotion) where {T} = Path(randn(rng, T, bm.num_terms))
basemeasure(b::BrownianMotion)  = b

struct Path{V}
    terms::V
end

logdensity_def(::BrownianMotion, ::Path) = 0.0

struct TiltedBrownianMotion <: AbstractMeasure
    path::Path
    sigma::Float64
end

using FillArrays
zeropath(n) = Path(Zeros(n))

insupport(::TiltedBrownianMotion, ::Path) = true
basemeasure(tbm::TiltedBrownianMotion) = TiltedBrownianMotion(zeropath(length(tbm.path.terms)), tbm.sigma)
import Base.==
==(tbm::TiltedBrownianMotion, bm::BrownianMotion) = iszero(tbm.path.terms) && tbm.sigma == 1
==(tbm1::TiltedBrownianMotion, tbm2::TiltedBrownianMotion) = tbm1.path.terms == tbm2.path.terms && tbm1.sigma == tbm2.sigma

Base.rand(rng::Random.AbstractRNG, ::Type{T}, bm::TiltedBrownianMotion) where {T} = Path(bm.path.terms + bm.sigma*randn(rng, T, length(bm.path.terms)))

function logdensity_def(tbm::TiltedBrownianMotion, path::Path)
    # TODO: Account for possible difference in number of terms
    n = length(path.terms)
    s = 0.0
    @inbounds for j in 1:n
        term_j = path.terms[j]
        s += logdensity_def(Normal(tbm.path.terms[j], tbm.sigma), term_j)
        s -= logdensity_def(Normal(σ = tbm.sigma), term_j)
    end
    return s
end

function logdensity_rel(tbm::TiltedBrownianMotion, bm::BrownianMotion, path::Path)
    bm.num_terms == length(tbm.path.terms) || ArgumentError("Incompatible base measure")

    logdensity_def(tbm::TiltedBrownianMotion, path::Path)
end

function sin_basis(x, n)
    b = similar(x, (length(x), n))
    for j in 1:n
        k = j - 0.5
        for i in eachindex(x)
            b[i,j] =  sinpi(k * x[i]) / (k * π)
        end
    end
    return b
end

function (f::Path)(t::T) where {T}
    result = zero(T)
    for j in eachindex(f.terms)
        k = j - 0.5
        @inbounds result += f.terms[j] * sinpi(k * t) / k
    end
    result /= π
    return result
end

# ----------------------------------------------------

path = rand(BrownianMotion(1000));
tbm = TiltedBrownianMotion(path, 0.1);
logdensityof(tbm, path)

# ----------------------------------------------------

# using Plots
u = 0:0.001:1


f = rand(BrownianMotion(1000));
x = rand(10)
y = f.(x)
if PLOT
plt = plot(u, f.(u), label="truth", dpi=200)
scatter!(x,y, label="observed")
end

b = sin_basis(x, 1000)
y ≈ b * f.terms

sol = Path(b \ y);

nullsp = nullspace(b);

if PLOT

for j in 1:10
    g = Path(sol.terms + nullsp * randn(990))
    plot!(plt, u, g.(u), alpha=0.1, color=:black, label=false)
end
plt
plot!(plt, u, f.(u), label=false, dpi=200, color=1)
scatter!(plt, x,y, label=false, color=2)
Plots.title!("Conditional Brownian Motion")
png("brownian-posterior.png")
end
using Tilde

mh_step = @model target, proposal, x begin
    xᵒ ~ proposal(x)
    basemeasure(target) == basemeasure(proposal(x)) || ArgumentError("Mismatch of base measures")

    a = logdensity_def(target, xᵒ) - logdensity_def(target, x)
    a += logdensity_def(proposal(xᵒ), x) - logdensity_def(proposal(x), xᵒ)
    accept ~ Bernoulli(min(1, exp(a)))
    return ifelse(accept, xᵒ, x)
end

# use Metropolis assuming proposal has detailed balance with respect to base
db_mh_step = @model target, base, proposal, x begin
    xᵒ ~ proposal(x)
    # @assert that proposal has detailed balance for base
    a = logdensity_rel(target, base, xᵒ) - logdensity_rel(target, base, x)
    accept ~ Bernoulli(min(1, exp(a)))
    return ifelse(accept, xᵒ, x)
end

k = 100
terms = zeros(k)
terms[2:5] .= 2.0

target = TiltedBrownianMotion(Path(terms), 1.0)

# this works
proposal0(x) = BrownianMotion(k)
step0(x) = mh_step(target, proposal0, x)

# this also works, needs symmetry hard coded
ρ = 0.9
proposal(x) = TiltedBrownianMotion(Path(ρ*x.terms), sqrt(1.0 - ρ^2))

step_illegal(x) = mh_step(target, proposal, x)

step(x) = db_mh_step(target, BrownianMotion(k), proposal, x)

w0 = Path(zeros(k))
#densityof(𝒹(target, target), w0)

samples0 = collect(Iterators.take(rand(Chain(step0, Dirac(w0))), 10000))

#@test_throws ArgumentError
collect(Iterators.take(rand(Chain(step_illegal, Dirac(w0))), 10000))

samples = collect(Iterators.take(rand(Chain(step, Dirac(w0))), 10000))

m = mean(map(x->x.terms, samples))

if PLOT
using Plots
u = 0:0.01:1
plt = plot(u, samples[1].(u), color=1, legend=false, alpha=0.01, dpi=200)
for j in 2:10000
    plot!(u, samples[j].(u), color=1, legend=false, alpha=0.01, dpi=200)
end
plt
end
