# State
# =====

mutable struct State
    data::Vector{UInt8}
    position::Int
    fposition::Int

    function State(datasize::Integer)
        @assert datasize > 0
        return new(Vector{UInt8}(datasize), 1, 1)
    end
end

function bufferptr(state)
    return pointer(state.data, state.position)
end

function buffersize(state)
    return state.fposition - state.position
end

function marginptr(state)
    return pointer(state.data, state.fposition)
end

function marginsize(state)
    return endof(state.data) - state.fposition + 1
end
