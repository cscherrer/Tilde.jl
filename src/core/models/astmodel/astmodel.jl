struct Model{A,B,M<:GG.TypeLevel} <: AbstractModel{A,B,M}
    args::Vector{Symbol}
    body::Expr
end

function Model(theModule::Module, args::Vector{Symbol}, body::Expr)
    A = NamedTuple{Tuple(args)}

    B = to_type(body)
    M = to_type(theModule)
    return Model{A,B,M}(args, body)
end

model(m::Model) = m

# ModelClosure{A,B,M,Args,Obs} <: AbstractModel{A,B,M,Argvals,Obs}
#     model::Model{A,B,M}
#     argvals :: Argvals
#     obs :: Obs
# end

function Base.convert(::Type{Expr}, m::Model)
    numArgs = length(m.args)
    args = if numArgs == 1
        m.args[1]
    elseif numArgs > 1
        Expr(:tuple, [x for x in m.args]...)
    end

    body = m.body

    q = if numArgs == 0
        @q begin
            @model $body
        end
    else
        @q begin
            @model $(args) $body
        end
    end

    striplines(q).args[1]
end

Base.show(io::IO, m::Model) = println(io, convert(Expr, m))

function type2model(::Type{Model{A,B,M}}) where {A,B,M}
    args = [fieldnames(A)...]
    body = from_type(B)
    Model(from_type(M), convert(Vector{Symbol}, args), body)
end

# julia> using Tilde, MeasureTheory

# julia> m = @model begin
#        p ~ Uniform()
#        x ~ Bernoulli(p) |> iid(3)
#        end;

# julia> f = interpret(m);

# julia> f(NamedTuple()) do x,d,ctx
#            r = rand(d)
#            (r, merge(ctx, NamedTuple{(x,)}((r,))))
#        end
# (p = 0.3863623559358842, x = Bool[0, 0, 0])

# julia> f(0) do x,d,n
#            r = rand(d)
#            (r, n+1)
#        end
# 2

# julia> f
# function = (_tilde, _ctx0;) -> begin
#     begin
#         _ctx = _ctx0
#         (p, _ctx) = _tilde(:p, (Main).Uniform(), _ctx)
#         (x, _ctx) = _tilde(:x, (Main).:|>((Main).Bernoulli(p), (Main).iid(3)), _ctx)
#         return _ctx
#     end
# end
