# Decompressor Codecs
# ====================

abstract type DecompressorCodec <: TranscodingStreams.Codec end

function Base.show(io::IO, codec::DecompressorCodec)
    print(io, summary(codec), "(windowbits=$(codec.windowbits))")
end


# Gzip
# ----

struct GzipDecompressor <: DecompressorCodec
    zstream::ZStream
    windowbits::Int
end

"""
    GzipDecompressor(;windowbits=$(Z_DEFAULT_WINDOWBITS), gziponly=false)

Create a gzip decompressor codec.

If `gziponly` is `false`, this codec can decompress the zlib format as well.

Arguments
---------
- `windowbits`: size of history buffer (8..15)
- `gziponly`: flag to inactivate data format detection
"""
function GzipDecompressor(;windowbits::Integer=Z_DEFAULT_WINDOWBITS, gziponly::Bool=false)
    if !(8 ≤ windowbits ≤ 15)
        throw(ArgumentError("windowbits must be within 8..15"))
    end
    return GzipDecompressor(ZStream(), windowbits+(gziponly ? 16 : 32))
end

const GzipDecompressorStream{S} = TranscodingStream{GzipDecompressor,S} where S<:IO

"""
    GzipDecompressorStream(stream::IO; kwargs...)

Create a gzip decompression stream (see `GzipDecompressor` for `kwargs`).
"""
function GzipDecompressorStream(stream::IO; kwargs...)
    x, y = splitkwargs(kwargs, (:windowbits, :gziponly))
    return TranscodingStream(GzipDecompressor(;x...), stream; y...)
end


# Zlib
# ----

struct ZlibDecompressor <: DecompressorCodec
    zstream::ZStream
    windowbits::Int
end

"""
    ZlibDecompressor(;windowbits=$(Z_DEFAULT_WINDOWBITS))

Create a zlib decompression codec.

Arguments
---------
- `windowbits`: size of history buffer (8..15)
"""
function ZlibDecompressor(;windowbits::Integer=Z_DEFAULT_WINDOWBITS)
    if !(8 ≤ windowbits ≤ 15)
        throw(ArgumentError("windowbits must be within 8..15"))
    end
    return ZlibDecompressor(ZStream(), windowbits)
end

const ZlibDecompressorStream{S} = TranscodingStream{ZlibDecompressor,S} where S<:IO

"""
    ZlibDecompressorStream(stream::IO; kwargs...)

Create a deflate decompression stream (see `ZlibDecompressor` for `kwargs`).
"""
function ZlibDecompressorStream(stream::IO; kwargs...)
    x, y = splitkwargs(kwargs, (:windowbits,))
    return TranscodingStream(ZlibDecompressor(;x...), stream; y...)
end


# Deflate
# -------

struct DeflateDecompressor <: DecompressorCodec
    zstream::ZStream
    windowbits::Int
end

"""
    DeflateDecompressor(;windowbits=$(Z_DEFAULT_WINDOWBITS))

Create a deflate decompression codec.

Arguments
---------
- `windowbits`: size of history buffer (8..15)
"""
function DeflateDecompressor(;windowbits::Integer=Z_DEFAULT_WINDOWBITS)
    if !(8 ≤ windowbits ≤ 15)
        throw(ArgumentError("windowbits must be within 8..15"))
    end
    return DeflateDecompressor(ZStream(), -Int(windowbits))
end

const DeflateDecompressorStream{S} = TranscodingStream{DeflateDecompressor,S} where S<:IO

"""
    DeflateDecompressorStream(stream::IO; kwargs...)

Create a deflate decompression stream (see `DeflateDecompressor` for `kwargs`).
"""
function DeflateDecompressorStream(stream::IO; kwargs...)
    x, y = splitkwargs(kwargs, (:windowbits,))
    return TranscodingStream(DeflateDecompressor(;x...), stream; y...)
end


# Methods
# -------

function TranscodingStreams.initialize(codec::DecompressorCodec)
    code = inflate_init!(codec.zstream, codec.windowbits)
    if code != Z_OK
        zerror(codec.zstream, code)
    end
    return
end

function TranscodingStreams.finalize(codec::DecompressorCodec)
    zstream = codec.zstream
    if zstream.state != C_NULL
        code = inflate_end!(zstream)
        if code != Z_OK
            zerror(zstream, code)
        end
    end
    return
end

function TranscodingStreams.startproc(codec::DecompressorCodec, ::Symbol, error::Error)
    code = inflate_reset!(codec.zstream)
    if code == Z_OK
        return :ok
    else
        error[] = ErrorException(zlib_error_message(codec.zstream, code))
        return :error
    end
end

function TranscodingStreams.process(codec::DecompressorCodec, input::Memory, output::Memory, error::Error)
    zstream = codec.zstream
    zstream.next_in = input.ptr

    avail_in = min(input.size, typemax(UInt32))
    zstream.avail_in = avail_in
    zstream.next_out = output.ptr
    avail_out = min(output.size, typemax(UInt32))
    zstream.avail_out = avail_out
    code = inflate!(zstream, Z_NO_FLUSH)
    Δin = Int(avail_in - zstream.avail_in)
    Δout = Int(avail_out - zstream.avail_out)
    if code == Z_OK
        return Δin, Δout, :ok
    elseif code == Z_STREAM_END
        return Δin, Δout, :end
    else
        error[] = ErrorException(zlib_error_message(zstream, code))
        return Δin, Δout, :error
    end
end
