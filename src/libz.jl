# Libz Interfaces
# ===============

mutable struct ZStream
    next_in::Ptr{UInt8}
    avail_in::Cuint
    total_in::Culong

    next_out::Ptr{UInt8}
    avail_out::Cuint
    total_out::Culong

    msg::Ptr{UInt8}
    state::Ptr{Cvoid}

    zalloc::Ptr{Cvoid}
    zfree::Ptr{Cvoid}
    opaque::Ptr{Cvoid}

    data_type::Cint

    adler::Culong
    reserved::Culong
end

function ZStream()
    ZStream(
        # input
        C_NULL, 0, 0,
        # output
        C_NULL, 0, 0,
        # message and state
        C_NULL, C_NULL,
        # memory allocation
        C_NULL, C_NULL, C_NULL,
        # data type, adler and reserved
        0, 0, 0)
end

const Z_DEFAULT_COMPRESSION = Cint(-1)

const Z_OK         = Cint(0)
const Z_STREAM_END = Cint(1)
const Z_BUF_ERROR  = Cint(-5)

const Z_NO_FLUSH      = Cint(0)
const Z_SYNC_FLUSH    = Cint(2)
const Z_FINISH        = Cint(4)

# The deflate compression method
const Z_DEFLATED = Cint(8)

const Z_DEFAULT_STRATEGY = Cint(0)

const Z_DEFAULT_MEMLEVEL = Cint(8)
const Z_DEFAULT_WINDOWBITS = Cint(15)

function version()
    return unsafe_string(ccall((:zlibVersion, libz), Ptr{UInt8}, ()))
end

const zlib_version = version()

function deflate_init!(zstream::ZStream, level::Integer, windowbits::Integer)
    return ccall((:deflateInit2_, libz), Cint, (Ref{ZStream}, Cint, Cint, Cint, Cint, Cint, Cstring, Cint), zstream, level, Z_DEFLATED, windowbits, #=default memlevel=#8, #=default strategy=#0, zlib_version, sizeof(ZStream))
end

function deflate_reset!(zstream::ZStream)
    return ccall((:deflateReset, libz), Cint, (Ref{ZStream},), zstream)
end

function deflate_end!(zstream::ZStream)
    return ccall((:deflateEnd, libz), Cint, (Ref{ZStream},), zstream)
end

function deflate!(zstream::ZStream, flush::Integer)
    return ccall((:deflate, libz), Cint, (Ref{ZStream}, Cint), zstream, flush)
end

function inflate_init!(zstream::ZStream, windowbits::Integer)
    return ccall((:inflateInit2_, libz), Cint, (Ref{ZStream}, Cint, Cstring, Cint), zstream, windowbits, zlib_version, sizeof(ZStream))
end

function inflate_reset!(zstream::ZStream)
    return ccall((:inflateReset, libz), Cint, (Ref{ZStream},), zstream)
end

function inflate_end!(zstream::ZStream)
    return ccall((:inflateEnd, libz), Cint, (Ref{ZStream},), zstream)
end

function inflate!(zstream::ZStream, flush::Integer)
    return ccall((:inflate, libz), Cint, (Ref{ZStream}, Cint), zstream, flush)
end

function zerror(zstream::ZStream, code::Integer)
    return throw(ErrorException(zlib_error_message(zstream, code)))
end

function zlib_error_message(zstream::ZStream, code::Integer)
    if zstream.msg == C_NULL
        return "zlib error: <no message> (code: $(code))"
    else
        return "zlib error: $(unsafe_string(zstream.msg)) (code: $(code))"
    end
end
