
export tilde

@inline function tilde(m::Model)
    return _tilde(getmoduletypencoding(m), m)
end

# @inline function Base.tilde(m::ModelClosure) 
#     tilde(GLOBAL_RNG, m)
# end

# @inline function Base.tilde(m::DAGModel)
#     return _tilde(getmoduletypencoding(m), m, NamedTuple())(rng)
# end

# tilde(m::DAGModel) = tilde(GLOBAL_RNG, m)



# sourcetilde(m::DAGModel) = sourcetilde()(m)
# sourcetilde(jd::ModelClosure) = sourcetilde(jd.model)

export sourcetilde
function sourcetilde() 
    function(_m::Model)
        quote
            f -> let ~ = f 
                $(_m.body)
        end
        end
    end
end

@gg function _tilde(M::Type{<:TypeLevel}, _m::Model)
    body = type2model(_m) |> sourcetilde()
    @under_global from_type(_unwrap_type(M)) @q let M
        $body
    end
end

# @gg function _tilde(M::Type{<:TypeLevel}, _m::DAGModel, _args::NamedTuple{()})
#     body = type2model(_m) |> sourcetilde()
#     @under_global from_type(_unwrap_type(M)) @q let M
#         $body
#     end
# end
