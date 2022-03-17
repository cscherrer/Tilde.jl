# Tilde

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://cscherrer.github.io/Tilde.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://cscherrer.github.io/Tilde.jl/dev)
[![Build Status](https://github.com/cscherrer/Tilde.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/cscherrer/Tilde.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/cscherrer/Tilde.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/cscherrer/Tilde.jl)

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

julia> rand(m(x,10))
(σ = 0.2647077728206953, x = [0.06944713402659985, 0.3047980085884222, 0.07621300638873846])

julia> x
3-element Vector{Float64}:
 0.06944713402659985
 0.3047980085884222
 0.07621300638873846
```
