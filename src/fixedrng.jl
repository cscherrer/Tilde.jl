export FixedRNG
struct FixedRNG <: AbstractRNG end

Base.rand(::FixedRNG) = one(Float64) / 2
Random.randn(::FixedRNG) = zero(Float64)
Random.randexp(::FixedRNG) = one(Float64)

Base.rand(::FixedRNG, ::Type{T}) where {T<:Real} = one(T) / 2
Random.randn(::FixedRNG, ::Type{T}) where {T<:Real} = zero(T)
Random.randexp(::FixedRNG, ::Type{T}) where {T<:Real} = one(T)

# We need concrete type parameters to avoid amiguity for these cases
for T in [Float16, Float32, Float64]
    @eval begin
        Base.rand(::FixedRNG, ::Type{$T}) = one($T) / 2
        Random.randn(::FixedRNG, ::Type{$T}) = zero($T)
        Random.randexp(::FixedRNG, ::Type{$T}) = one($T)
    end
end
