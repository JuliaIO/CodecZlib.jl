# Compression Codecs
# ==================

abstract type CompressionCodec <: TranscodingStreams.Codec end


# Gzip
# ----

struct GzipCompression <: CompressionCodec
    zstream::ZStream
end

"""
    GzipCompression(;level=$(Z_DEFAULT_COMPRESSION), windowbits=$(Z_DEFAULT_WINDOWBITS))

Create a new gzip compression codec.
"""
function GzipCompression(;level::Integer=Z_DEFAULT_COMPRESSION,
                         windowbits::Integer=Z_DEFAULT_WINDOWBITS)
    if !(-1 ≤ level ≤ 9)
        throw(ArgumentError("compression level must be within -1..9"))
    elseif !(8 ≤ windowbits ≤ 15)
        throw(ArgumentError("windowbits must be within 8..15"))
    end
    zstream = ZStream()
    code = deflate_init!(zstream, level, windowbits+16)
    if code != Z_OK
        zerror(zstream, code)
    end
    return GzipCompression(zstream)
end

const GzipCompressionStream{S} = TranscodingStream{GzipCompression,S} where S<:IO

function GzipCompressionStream(stream::IO)
    return TranscodingStream(GzipCompression(), stream)
end


# Zlib
# ----

struct ZlibCompression <: CompressionCodec
    zstream::ZStream
end

"""
    ZlibCompression(;level=$(Z_DEFAULT_COMPRESSION), windowbits=$(Z_DEFAULT_WINDOWBITS))

Create a new zlib compression codec.
"""
function ZlibCompression(;level::Integer=Z_DEFAULT_COMPRESSION,
                         windowbits::Integer=Z_DEFAULT_WINDOWBITS)
    if !(-1 ≤ level ≤ 9)
        throw(ArgumentError("compression level must be within -1..9"))
    elseif !(8 ≤ windowbits ≤ 15)
        throw(ArgumentError("windowbits must be within 8..15"))
    end
    zstream = ZStream()
    code = deflate_init!(zstream, level, windowbits)
    if code != Z_OK
        zerror(zstream, code)
    end
    return ZlibCompression(zstream)
end

const ZlibCompressionStream{S} = TranscodingStream{ZlibCompression,S} where S<:IO

function ZlibCompressionStream(stream::IO)
    return TranscodingStream(ZlibCompression(), stream)
end


# Raw
# ---

struct RawCompression <: CompressionCodec
    zstream::ZStream
end

"""
    RawCompression(;level=$(Z_DEFAULT_COMPRESSION), windowbits=$(Z_DEFAULT_COMPRESSION))

Create a new raw compression codec.
"""
function RawCompression(;level::Integer=Z_DEFAULT_COMPRESSION,
                        windowbits::Integer=Z_DEFAULT_WINDOWBITS)
    if !(-1 ≤ level ≤ 9)
        throw(ArgumentError("compression level must be within -1..9"))
    elseif !(8 ≤ windowbits ≤ 15)
        throw(ArgumentError("windowbits must be within 8..15"))
    end
    zstream = ZStream()
    code = deflate_init!(zstream, level, -Int(windowbits))
    if code != Z_OK
        zerror(zstream, code)
    end
    return RawCompression(zstream)
end

const RawCompressionStream{S} = TranscodingStream{RawCompression,S} where S<:IO

function RawCompressionStream(stream::IO)
    return TranscodingStream(RawCompression(), stream)
end


# Methods
# -------

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

function TranscodingStreams.finalize(codec::CompressionCodec)
    code = deflate_end!(codec.zstream)
    if code != Z_OK
        zerror(codec.zstream, code)
    end
    return
end
