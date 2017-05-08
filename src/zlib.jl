# Zlib Inflation and Deflation Codecs
# ===================================

struct ZlibInflation <: Codec
    state::State
    zstream::Libz.ZStream
end

function ZlibInflation(;windowbits=15)
    zstream = Libz.ZStream()
    Libz.init_inflate!(zstream, windowbits)
    return ZlibInflation(State(1024), zstream)
end

function ZlibInflationStream(stream::IO)
    return TranscodingStream(ZlibInflation, stream)
end

struct ZlibDeflation <: Codec
    state::State
    zstream::Libz.ZStream
end

function ZlibDeflation(;level=6, windowbits=15)
    zstream = Libz.ZStream()
    Libz.init_deflate!(zstream, level, Libz.Z_DEFLATED, windowbits, #=memlevel=#8, Libz.Z_DEFAULT_STRATEGY)
    return ZlibDeflation(State(1024), zstream)
end

function ZlibDeflationStream(stream::IO)
    return TranscodingStream(ZlibDeflation, stream)
end
