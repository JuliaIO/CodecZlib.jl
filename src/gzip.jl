# Gzip Inflation and Deflation Codecs
# ===================================

struct GzipInflation <: Codec
    state::State
    zstream::Libz.ZStream
end

function GzipInflation(;windowbits=15, gziponly=false)
    zstream = Libz.ZStream()
    if gziponly
        windowbits += 16
    else
        windowbits += 32
    end
    Libz.init_inflate!(zstream, windowbits)
    return GzipInflation(State(1024), zstream)
end

function GzipInflationStream(stream::IO)
    return TranscodingStream(GzipInflation, stream)
end

struct GzipDeflation <: Codec
    state::State
    zstream::Libz.ZStream
end

function GzipDeflation()
    zstream = Libz.ZStream()
    Libz.init_deflate!(zstream; windowbits=16+15)
    return GzipDeflation(State(1024), zstream)
end

function GzipDeflationStream(stream::IO)
    return TranscodingStream(GzipDeflation, stream)
end
