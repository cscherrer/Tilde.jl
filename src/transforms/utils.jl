# using SimpleGraphs: vlist, elist, out_neighbors

# Type piracy, this should really go in SimpleGraphs
# OTOH there's not anything else this could really mean
# function SimpleGraphs.components(g::SimpleDigraph)
#     SimpleGraphs.components(convert(SimpleGraph, g))
# end

# function _before(g::SimpleDigraph, v)
#     parents = in_neighbors(g, v)
#     for i in parents
#         append!(parents, _before(g, i))
#     end
#     return parents
# end

# before(g::SimpleDigraph, v; inclusive = true) = inclusive ? push!(_before(g, v), v) : _before(g, v)
# function before(g::SimpleDigraph, vs...; inclusive = true)
#     parents = inclusive ? collect(vs) : Symbol[]
#     for v in vs
#         append!(parents, before(g, v, inclusive = inclusive))
#     end
#     if !inclusive
#         setdiff!(parents, vs)
#     end
#     return unique!(parents)
# end

# notbefore(g::SimpleDigraph, vs...; inclusive = false) = setdiff(vlist(g), before(g, vs...; inclusive = !inclusive))

# function _after(g::SimpleDigraph, v)
#     children = out_neighbors(g, v)
#     for i in children
#         append!(children, _after(g, i))
#     end
#     return children
# end

# after(g::SimpleDigraph, v; inclusive = true) = inclusive ? push!(_after(g, v), v) : _after(g, v)

# function after(g::SimpleDigraph, vs...; inclusive = true)
#     children = inclusive ? collect(vs) : Symbol[]
#     for v in vs
#         append!(children, after(g, v, inclusive = inclusive))
#     end
#     if !inclusive
#         setdiff!(children, vs)
#     end
#     return unique!(children)
# end

# notafter(g::SimpleDigraph, vs...; inclusive = false) = setdiff(vlist(g), after(g, vs...; inclusive = !inclusive))

# function assemblefrom(m::DAGModel, params, args)
#     theModule = getmodule(m)
#     m_init = DAGModel(theModule, args, NamedTuple(), NamedTuple(), nothing)
#     m = foldl(params; init=m_init) do m0,v
#         merge(m0, DAGModel(theModule, findStatement(m, v)))
#     end
#     return m
# end

getReturn(am::AbstractModel) =model(am).retn
