
toargs(vs::Vector{Symbol}) = Tuple(vs)
toargs(vs::NTuple{N,Symbol} where {N}) = vs

macro model(vs::Expr, expr::Expr)
    theModule = __module__
    @assert vs.head == :tuple
    @assert expr.head == :block
    Model(theModule, Vector{Symbol}(vs.args), expr)
end

macro model(v::Symbol, expr::Expr)
    theModule = __module__
    Model(theModule, [v], expr)
end

macro model(expr::Expr)
    theModule = __module__
    Model(theModule, Vector{Symbol}(), expr)
end
