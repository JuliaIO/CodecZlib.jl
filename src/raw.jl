# Raw Inflation and Deflation Codecs
# ==================================

struct RawInflation <: Codec
    state::State
    zstream::Libz.ZStream
end

function RawInflation(;windowbits=15)
    zstream = Libz.ZStream()
    windowbits = windowbits * -1
    Libz.init_inflate!(zstream, windowbits)
    return RawInflation(State(1024), zstream)
end

function RawInflationStream(stream::IO)
    return TranscodingStream(RawInflation, stream)
end

struct RawDeflation <: Codec
    state::State
    zstream::Libz.ZStream
end

function RawDeflation(;level=6, windowbits=15)
    zstream = Libz.ZStream()
    windowbits = windowbits * -1
    Libz.init_deflate!(zstream, level, Libz.Z_DEFLATED, windowbits, #=memlevel=#8, Libz.Z_DEFAULT_STRATEGY)
    return RawDeflation(State(1024), zstream)
end

function RawDeflationStream(stream::IO)
    return TranscodingStream(RawDeflation, stream)
end
