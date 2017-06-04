# Decompression Codecs
# ====================

abstract type DecompressionCodec <: TranscodingStreams.Codec end


# Gzip
# ----

struct GzipDecompression <: DecompressionCodec
    zstream::ZStream
    windowbits::Int
end

"""
    GzipDecompression(;windowbits=$(Z_DEFAULT_WINDOWBITS), gziponly=false)

Create a new gzip decompressor codec.
"""
function GzipDecompression(;windowbits::Integer=Z_DEFAULT_WINDOWBITS, gziponly::Bool=false)
    if !(8 ≤ windowbits ≤ 15)
        throw(ArgumentError("windowbits must be within 8..15"))
    end
    return GzipDecompression(ZStream(), windowbits+(gziponly?16:32))
end

const GzipDecompressionStream{S} = TranscodingStream{GzipDecompression,S} where S<:IO

"""
    GzipDecompressionStream(stream::IO)

Create a gzip decompression stream.
"""
function GzipDecompressionStream(stream::IO)
    return TranscodingStream(GzipDecompression(), stream)
end


# Zlib
# ----

struct ZlibDecompression <: DecompressionCodec
    zstream::ZStream
    windowbits::Int
end

"""
    ZlibDecompression(;windowbits=$(Z_DEFAULT_WINDOWBITS))

Create a new zlib decompression codec.
"""
function ZlibDecompression(;windowbits::Integer=Z_DEFAULT_WINDOWBITS)
    if !(8 ≤ windowbits ≤ 15)
        throw(ArgumentError("windowbits must be within 8..15"))
    end
    return ZlibDecompression(ZStream(), windowbits)
end

const ZlibDecompressionStream{S} = TranscodingStream{ZlibDecompression,S} where S<:IO

"""
    ZlibDecompressionStream(stream::IO)

Create a deflate decompression stream.
"""
function ZlibDecompressionStream(stream::IO)
    return TranscodingStream(ZlibDecompression(), stream)
end


# Deflate
# -------

struct DeflateDecompression <: DecompressionCodec
    zstream::ZStream
    windowbits::Int
end

"""
    DeflateDecompression(;windowbits=$(Z_DEFAULT_WINDOWBITS))

Create a new deflate decompression codec.
"""
function DeflateDecompression(;windowbits::Integer=Z_DEFAULT_WINDOWBITS)
    if !(8 ≤ windowbits ≤ 15)
        throw(ArgumentError("windowbits must be within 8..15"))
    end
    return DeflateDecompression(ZStream(), -Int(windowbits))
end

const DeflateDecompressionStream{S} = TranscodingStream{DeflateDecompression,S} where S<:IO

"""
    DeflateDecompressionStream(stream::IO)

Create a deflate decompression stream.
"""
function DeflateDecompressionStream(stream::IO)
    return TranscodingStream(DeflateDecompression(), stream)
end


# Methods
# -------

function TranscodingStreams.initialize(codec::DecompressionCodec)
    code = inflate_init!(codec.zstream, codec.windowbits)
    if code != Z_OK
        zerror(codec.zstream, code)
    end
    finalizer(codec.zstream, free_inflate!)
    return
end

function TranscodingStreams.finalize(codec::DecompressionCodec)
    free_inflate!(codec.zstream)
end

# Free zstream if needed.
function free_inflate!(zstream::ZStream)
    if zstream.state != C_NULL
        code = inflate_end!(zstream)
        if code != Z_OK
            zerror(zstream, code)
        end
    end
    return
end

function TranscodingStreams.startproc(codec::DecompressionCodec, ::Symbol)
    code = inflate_reset!(codec.zstream)
    if code != Z_OK
        zerror(codec.zstream, code)
    end
    return :ok
end

function TranscodingStreams.process(codec::DecompressionCodec, input::Memory, output::Memory)
    zstream = codec.zstream
    zstream.next_in = input.ptr
    zstream.avail_in = input.size
    zstream.next_out = output.ptr
    zstream.avail_out = output.size
    code = inflate!(zstream, Z_NO_FLUSH)
    Δin = Int(input.size - zstream.avail_in)
    Δout = Int(output.size - zstream.avail_out)
    if code == Z_OK
        return Δin, Δout, :ok
    elseif code == Z_STREAM_END
        return Δin, Δout, :end
    else
        zerror(zstream, code)
    end
end
