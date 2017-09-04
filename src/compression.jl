# Compression Codecs
# ==================

abstract type CompressionCodec <: TranscodingStreams.Codec end

function Base.show(io::IO, codec::CompressionCodec)
    print(io, summary(codec), "(level=$(codec.level), windowbits=$(codec.windowbits))")
end


# Gzip
# ----

struct GzipCompression <: CompressionCodec
    zstream::ZStream
    level::Int
    windowbits::Int
end

"""
    GzipCompression(;level=$(Z_DEFAULT_COMPRESSION), windowbits=$(Z_DEFAULT_WINDOWBITS))

Create a gzip compression codec.

Arguments
---------
- `level`: compression level (-1..9)
- `windowbits`: size of history buffer (8..15)
"""
function GzipCompression(;level::Integer=Z_DEFAULT_COMPRESSION,
                         windowbits::Integer=Z_DEFAULT_WINDOWBITS)
    if !(-1 ≤ level ≤ 9)
        throw(ArgumentError("compression level must be within -1..9"))
    elseif !(8 ≤ windowbits ≤ 15)
        throw(ArgumentError("windowbits must be within 8..15"))
    end
    return GzipCompression(ZStream(), level, windowbits+16)
end

const GzipCompressionStream{S} = TranscodingStream{GzipCompression,S} where S<:IO

"""
    GzipCompressionStream(stream::IO; kwargs...)

Create a gzip compression stream (see `GzipCompression` for `kwargs`).
"""
function GzipCompressionStream(stream::IO; kwargs...)
    return TranscodingStream(GzipCompression(;kwargs...), stream)
end


# Zlib
# ----

struct ZlibCompression <: CompressionCodec
    zstream::ZStream
    level::Int
    windowbits::Int
end

"""
    ZlibCompression(;level=$(Z_DEFAULT_COMPRESSION), windowbits=$(Z_DEFAULT_WINDOWBITS))

Create a zlib compression codec.

Arguments
---------
- `level`: compression level (-1..9)
- `windowbits`: size of history buffer (8..15)
"""
function ZlibCompression(;level::Integer=Z_DEFAULT_COMPRESSION,
                         windowbits::Integer=Z_DEFAULT_WINDOWBITS)
    if !(-1 ≤ level ≤ 9)
        throw(ArgumentError("compression level must be within -1..9"))
    elseif !(8 ≤ windowbits ≤ 15)
        throw(ArgumentError("windowbits must be within 8..15"))
    end
    return ZlibCompression(ZStream(), level, windowbits)
end

const ZlibCompressionStream{S} = TranscodingStream{ZlibCompression,S} where S<:IO

"""
    ZlibCompressionStream(stream::IO)

Create a zlib compression stream (see `ZlibCompression` for `kwargs`).
"""
function ZlibCompressionStream(stream::IO; kwargs...)
    return TranscodingStream(ZlibCompression(;kwargs...), stream)
end


# Deflate
# -------

struct DeflateCompression <: CompressionCodec
    zstream::ZStream
    level::Int
    windowbits::Int
end

"""
    DeflateCompression(;level=$(Z_DEFAULT_COMPRESSION), windowbits=$(Z_DEFAULT_COMPRESSION))

Create a deflate compression codec.

Arguments
---------
- `level`: compression level (-1..9)
- `windowbits`: size of history buffer (8..15)
"""
function DeflateCompression(;level::Integer=Z_DEFAULT_COMPRESSION,
                        windowbits::Integer=Z_DEFAULT_WINDOWBITS)
    if !(-1 ≤ level ≤ 9)
        throw(ArgumentError("compression level must be within -1..9"))
    elseif !(8 ≤ windowbits ≤ 15)
        throw(ArgumentError("windowbits must be within 8..15"))
    end
    return DeflateCompression(ZStream(), level, -Int(windowbits))
end

const DeflateCompressionStream{S} = TranscodingStream{DeflateCompression,S} where S<:IO

"""
    DeflateCompressionStream(stream::IO; kwargs...)

Create a deflate compression stream (see `DeflateCompression` for `kwargs`).
"""
function DeflateCompressionStream(stream::IO; kwargs...)
    return TranscodingStream(DeflateCompression(;kwargs...), stream)
end


# Methods
# -------

function TranscodingStreams.initialize(codec::CompressionCodec)
    code = deflate_init!(codec.zstream, codec.level, codec.windowbits)
    if code != Z_OK
        zerror(codec.zstream, code)
    end
    return
end

function TranscodingStreams.finalize(codec::CompressionCodec)
    zstream = codec.zstream
    if zstream.state != C_NULL
        code = deflate_end!(zstream)
        if code != Z_OK
            zerror(zstream, code)
        end
    end
    return
end

function TranscodingStreams.startproc(codec::CompressionCodec, state::Symbol, error::Error)
    code = deflate_reset!(codec.zstream)
    if code == Z_OK
        return :ok
    else
        error[] = ErrorException(zlib_error_message(codec.zstream, code))
        return :error
    end
end

function TranscodingStreams.process(codec::CompressionCodec, input::Memory, output::Memory, error::Error)
    zstream = codec.zstream
    zstream.next_in = input.ptr
    zstream.avail_in = input.size
    zstream.next_out = output.ptr
    zstream.avail_out = output.size
    code = deflate!(zstream, input.size > 0 ? Z_NO_FLUSH : Z_FINISH)
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
