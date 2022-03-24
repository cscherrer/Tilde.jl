# Tilde

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://cscherrer.github.io/Tilde.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://cscherrer.github.io/Tilde.jl/dev)
[![Build Status](https://github.com/cscherrer/Tilde.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/cscherrer/Tilde.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/cscherrer/Tilde.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/cscherrer/Tilde.jl)

WIP, successor to [Soss.jl](https://github.com/cscherrer/Soss.jl)

For a high-level description of Tilde's design, check out [this blog post](https://informativeprior.com/blog/2022/03-21-tilde/)

```julia
julia> m = @model (x, s) begin
        σ ~ Exponential()
        @inbounds x[1] ~ Normal(σ = σ)
        n = length(x)
        @inbounds for j = 2:n
            x[j] ~ StudentT(1.5, x[j - 1], σ)
        end
    end;
    
julia> x = zeros(3);

julia> r = rand(m(x,10))
(σ = 9.096155145583953, x = [14.876934886768867, 6.612967845518229, 2.045770246490428])

julia> x
3-element Vector{Float64}:
 14.876934886768867
  6.612967845518229
  2.045770246490428

julia> ℓ = logdensityof(m(x, 1.0) | (;x), (σ = 1.0,))
-122.91114458882001
