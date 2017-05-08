# Inflation Methods
# =================

const InflationCodec = Union{GzipInflation,ZlibInflation,RawInflation}

function process(::Type{ReadMode}, codec::InflationCodec, source::IO, output::Ptr{UInt8}, nbytes::Int)::Tuple{Int,ProcCode}
    # fill buffer
    state = codec.state
    if state.position == state.fposition
        state.position = state.fposition = 1
    end
    state.fposition += TranscodingStreams.unsafe_read(source, marginptr(state), marginsize(state))

    # set up zstream
    zstream = codec.zstream
    zstream.next_in = bufferptr(state)
    zstream.avail_in = buffersize(state)
    zstream.next_out = output
    zstream.avail_out = nbytes

    # inflate data
    code = Libz.inflate!(zstream, Libz.Z_NO_FLUSH)
    diff_in = buffersize(state) - zstream.avail_in
    diff_out = nbytes - zstream.avail_out
    state.position += diff_in
    if code == Libz.Z_OK
        return diff_out, PROC_OK
    elseif code == Libz.Z_STREAM_END
        return diff_out, PROC_FINISH
    else
        Libz.zerror(zstream, code)
    end
end

function process(::Type{WriteMode}, codec::InflationCodec, sink::IO, input::Ptr{UInt8}, nbytes::Int)::Tuple{Int,ProcCode}
    # flush buffer
    state = codec.state
    state.position += unsafe_write(sink, bufferptr(state), buffersize(state))
    if state.position == state.fposition
        state.position = state.fposition = 1
    end

    # set up zstream
    zstream = codec.zstream
    zstream.next_in = input
    zstream.avail_in = nbytes
    zstream.next_out = marginptr(state)
    zstream.avail_out = marginsize(state)

    # inflate data
    code = Libz.inflate!(zstream, Libz.Z_NO_FLUSH)
    diff_in = nbytes - zstream.avail_in
    diff_out = marginsize(state) - zstream.avail_out
    state.fposition += diff_out
    if code == Libz.Z_OK
        return diff_in, PROC_OK
    elseif code == Libz.Z_STREAM_END
        return diff_in, PROC_FINISH
    else
        Libz.zerror(zstream, code)
    end
end

function finish(::Type{WriteMode}, codec::InflationCodec, sink::IO)
    state = codec.state
    while buffersize(state) > 0
        state.position += unsafe_write(sink, bufferptr(state), buffersize(state))
    end
    return
end
