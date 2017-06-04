# Compression Codecs
# ==================

abstract type CompressionCodec <: TranscodingStreams.Codec end


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
    GzipCompressionStream(stream::IO)

Create a gzip compression stream.
"""
function GzipCompressionStream(stream::IO)
    return TranscodingStream(GzipCompression(), stream)
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

Create a zlib compression stream.
"""
function ZlibCompressionStream(stream::IO)
    return TranscodingStream(ZlibCompression(), stream)
end


# Raw
# ---

struct RawCompression <: CompressionCodec
    zstream::ZStream
    level::Int
    windowbits::Int
end

"""
    RawCompression(;level=$(Z_DEFAULT_COMPRESSION), windowbits=$(Z_DEFAULT_COMPRESSION))

Create a raw compression codec.
"""
function RawCompression(;level::Integer=Z_DEFAULT_COMPRESSION,
                        windowbits::Integer=Z_DEFAULT_WINDOWBITS)
    if !(-1 ≤ level ≤ 9)
        throw(ArgumentError("compression level must be within -1..9"))
    elseif !(8 ≤ windowbits ≤ 15)
        throw(ArgumentError("windowbits must be within 8..15"))
    end
    return RawCompression(ZStream(), level, -Int(windowbits))
end

const RawCompressionStream{S} = TranscodingStream{RawCompression,S} where S<:IO

"""
    RawCompressionStream(stream::IO)

Create a raw compression stream.
"""
function RawCompressionStream(stream::IO)
    return TranscodingStream(RawCompression(), stream)
end


# Methods
# -------

function TranscodingStreams.initialize(codec::CompressionCodec)
    code = deflate_init!(codec.zstream, codec.level, codec.windowbits)
    if code != Z_OK
        zerror(zstream, code)
    end
    finalizer(codec.zstream, deflate_end!)
    return
end

function TranscodingStreams.finalize(codec::CompressionCodec)
    code = deflate_end!(codec.zstream)
    if code != Z_OK
        zerror(codec.zstream, code)
    end
    return
end

function TranscodingStreams.startproc(codec::CompressionCodec)
    code = deflate_reset!(codec.zstream)
    if code != Z_OK
        zerror(codec.zstream, code)
    end
    return :ok
end

function TranscodingStreams.process(codec::CompressionCodec, input::Memory, output::Memory)
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
        zerror(zstream, code)
    end
end
