# Compressor Codecs
# ==================

abstract type CompressorCodec <: TranscodingStreams.Codec end

function Base.show(io::IO, codec::CompressorCodec)
    print(io, summary(codec), "(level=$(codec.level), windowbits=$(codec.windowbits))")
end


# Gzip
# ----

struct GzipCompressor <: CompressorCodec
    zstream::ZStream
    level::Int
    windowbits::Int
end

"""
    GzipCompressor(;level=$(Z_DEFAULT_COMPRESSION), windowbits=$(Z_DEFAULT_WINDOWBITS))

Create a gzip compression codec.

Arguments
---------
- `level`: compression level (-1..9)
- `windowbits`: size of history buffer (8..15)
"""
function GzipCompressor(;level::Integer=Z_DEFAULT_COMPRESSION,
                         windowbits::Integer=Z_DEFAULT_WINDOWBITS)
    if !(-1 ≤ level ≤ 9)
        throw(ArgumentError("compression level must be within -1..9"))
    elseif !(8 ≤ windowbits ≤ 15)
        throw(ArgumentError("windowbits must be within 8..15"))
    end
    return GzipCompressor(ZStream(), level, windowbits+16)
end

const GzipCompressorStream{S} = TranscodingStream{GzipCompressor,S} where S<:IO

"""
    GzipCompressorStream(stream::IO; kwargs...)

Create a gzip compression stream (see `GzipCompressor` for `kwargs`).
"""
function GzipCompressorStream(stream::IO; kwargs...)
    x, y = splitkwargs(kwargs, (:level, :windowbits))
    return TranscodingStream(GzipCompressor(;x...), stream; y...)
end


# Zlib
# ----

struct ZlibCompressor <: CompressorCodec
    zstream::ZStream
    level::Int
    windowbits::Int
end

"""
    ZlibCompressor(;level=$(Z_DEFAULT_COMPRESSION), windowbits=$(Z_DEFAULT_WINDOWBITS))

Create a zlib compression codec.

Arguments
---------
- `level`: compression level (-1..9)
- `windowbits`: size of history buffer (8..15)
"""
function ZlibCompressor(;level::Integer=Z_DEFAULT_COMPRESSION,
                         windowbits::Integer=Z_DEFAULT_WINDOWBITS)
    if !(-1 ≤ level ≤ 9)
        throw(ArgumentError("compression level must be within -1..9"))
    elseif !(8 ≤ windowbits ≤ 15)
        throw(ArgumentError("windowbits must be within 8..15"))
    end
    return ZlibCompressor(ZStream(), level, windowbits)
end

const ZlibCompressorStream{S} = TranscodingStream{ZlibCompressor,S} where S<:IO

"""
    ZlibCompressorStream(stream::IO)

Create a zlib compression stream (see `ZlibCompressor` for `kwargs`).
"""
function ZlibCompressorStream(stream::IO; kwargs...)
    x, y = splitkwargs(kwargs, (:level, :windowbits))
    return TranscodingStream(ZlibCompressor(;x...), stream; y...)
end


# Deflate
# -------

struct DeflateCompressor <: CompressorCodec
    zstream::ZStream
    level::Int
    windowbits::Int
end

"""
    DeflateCompressor(;level=$(Z_DEFAULT_COMPRESSION), windowbits=$(Z_DEFAULT_COMPRESSION))

Create a deflate compression codec.

Arguments
---------
- `level`: compression level (-1..9)
- `windowbits`: size of history buffer (8..15)
"""
function DeflateCompressor(;level::Integer=Z_DEFAULT_COMPRESSION,
                        windowbits::Integer=Z_DEFAULT_WINDOWBITS)
    if !(-1 ≤ level ≤ 9)
        throw(ArgumentError("compression level must be within -1..9"))
    elseif !(8 ≤ windowbits ≤ 15)
        throw(ArgumentError("windowbits must be within 8..15"))
    end
    return DeflateCompressor(ZStream(), level, -Int(windowbits))
end

const DeflateCompressorStream{S} = TranscodingStream{DeflateCompressor,S} where S<:IO

"""
    DeflateCompressorStream(stream::IO; kwargs...)

Create a deflate compression stream (see `DeflateCompressor` for `kwargs`).
"""
function DeflateCompressorStream(stream::IO; kwargs...)
    x, y = splitkwargs(kwargs, (:level, :windowbits))
    return TranscodingStream(DeflateCompressor(;x...), stream; y...)
end


# Methods
# -------

function TranscodingStreams.initialize(codec::CompressorCodec)
    code = deflate_init!(codec.zstream, codec.level, codec.windowbits)
    if code != Z_OK
        zerror(codec.zstream, code)
    end
    return
end

function TranscodingStreams.finalize(codec::CompressorCodec)
    zstream = codec.zstream
    if zstream.state != C_NULL
        code = deflate_end!(zstream)
        if code != Z_OK
            zerror(zstream, code)
        end
    end
    return
end

function TranscodingStreams.startproc(codec::CompressorCodec, state::Symbol, error::Error)
    code = deflate_reset!(codec.zstream)
    if code == Z_OK
        return :ok
    else
        error[] = ErrorException(zlib_error_message(codec.zstream, code))
        return :error
    end
end

function TranscodingStreams.process(codec::CompressorCodec, input::Memory, output::Memory, error::Error)
    zstream = codec.zstream
    zstream.next_in = input.ptr
    avail_in = min(input.size, typemax(UInt32))
    zstream.avail_in = avail_in
    zstream.next_out = output.ptr
    avail_out = min(output.size, typemax(UInt32))
    zstream.avail_out = avail_out
    code = deflate!(zstream, zstream.avail_in > 0 ? Z_NO_FLUSH : Z_FINISH)
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
