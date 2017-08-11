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

Create a gzip decompressor codec.

If `gziponly` is `false`, this codec can decompress the zlib format as well.

Arguments
---------
- `windowbits`: size of history buffer (8..15)
- `gziponly`: flag to inactivate data format detection
"""
function GzipDecompression(;windowbits::Integer=Z_DEFAULT_WINDOWBITS, gziponly::Bool=false)
    if !(8 ≤ windowbits ≤ 15)
        throw(ArgumentError("windowbits must be within 8..15"))
    end
    return GzipDecompression(ZStream(), windowbits+(gziponly?16:32))
end

const GzipDecompressionStream{S} = TranscodingStream{GzipDecompression,S} where S<:IO

"""
    GzipDecompressionStream(stream::IO; kwargs...)

Create a gzip decompression stream (see `GzipDecompression` for `kwargs`).
"""
function GzipDecompressionStream(stream::IO; kwargs...)
    return TranscodingStream(GzipDecompression(;kwargs...), stream)
end


# Zlib
# ----

struct ZlibDecompression <: DecompressionCodec
    zstream::ZStream
    windowbits::Int
end

"""
    ZlibDecompression(;windowbits=$(Z_DEFAULT_WINDOWBITS))

Create a zlib decompression codec.

Arguments
---------
- `windowbits`: size of history buffer (8..15)
"""
function ZlibDecompression(;windowbits::Integer=Z_DEFAULT_WINDOWBITS)
    if !(8 ≤ windowbits ≤ 15)
        throw(ArgumentError("windowbits must be within 8..15"))
    end
    return ZlibDecompression(ZStream(), windowbits)
end

const ZlibDecompressionStream{S} = TranscodingStream{ZlibDecompression,S} where S<:IO

"""
    ZlibDecompressionStream(stream::IO; kwargs...)

Create a deflate decompression stream (see `ZlibDecompression` for `kwargs`).
"""
function ZlibDecompressionStream(stream::IO; kwargs...)
    return TranscodingStream(ZlibDecompression(;kwargs...), stream)
end


# Deflate
# -------

struct DeflateDecompression <: DecompressionCodec
    zstream::ZStream
    windowbits::Int
end

"""
    DeflateDecompression(;windowbits=$(Z_DEFAULT_WINDOWBITS))

Create a deflate decompression codec.

Arguments
---------
- `windowbits`: size of history buffer (8..15)
"""
function DeflateDecompression(;windowbits::Integer=Z_DEFAULT_WINDOWBITS)
    if !(8 ≤ windowbits ≤ 15)
        throw(ArgumentError("windowbits must be within 8..15"))
    end
    return DeflateDecompression(ZStream(), -Int(windowbits))
end

const DeflateDecompressionStream{S} = TranscodingStream{DeflateDecompression,S} where S<:IO

"""
    DeflateDecompressionStream(stream::IO; kwargs...)

Create a deflate decompression stream (see `DeflateDecompression` for `kwargs`).
"""
function DeflateDecompressionStream(stream::IO; kwargs...)
    return TranscodingStream(DeflateDecompression(;kwargs...), stream)
end


# Methods
# -------

function TranscodingStreams.initialize(codec::DecompressionCodec)
    code = inflate_init!(codec.zstream, codec.windowbits)
    if code != Z_OK
        zerror(codec.zstream, code)
    end
    return
end

function TranscodingStreams.finalize(codec::DecompressionCodec)
    zstream = codec.zstream
    if zstream.state != C_NULL
        code = inflate_end!(zstream)
        if code != Z_OK
            zerror(zstream, code)
        end
    end
    return
end

function TranscodingStreams.startproc(codec::DecompressionCodec, ::Symbol, error::Error)
    code = inflate_reset!(codec.zstream)
    if code == Z_OK
        return :ok
    else
        error[] = ErrorException(zlib_error_message(codec.zstream, code))
        return :error
    end
end

function TranscodingStreams.process(codec::DecompressionCodec, input::Memory, output::Memory, error::Error)
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
        error[] = ErrorException(zlib_error_message(zstream, code))
        return Δin, Δout, :error
    end
end
