__precompile__()

module CodecZlib

export
    # gzip
    GzipCompressor,
    GzipCompressorStream,
    GzipDecompressor,
    GzipDecompressorStream,

    # zlib
    ZlibCompressor,
    ZlibCompressorStream,
    ZlibDecompressor,
    ZlibDecompressorStream,

    # deflate
    DeflateCompressor,
    DeflateCompressorStream,
    DeflateDecompressor,
    DeflateDecompressorStream

import TranscodingStreams:
    TranscodingStreams,
    TranscodingStream,
    Memory,
    Error,
    initialize,
    finalize

# TODO: This method will be added in the next version of TranscodingStreams.jl.
function splitkwargs(kwargs, keys)
    hits = []
    others = []
    for kwarg in kwargs
        push!(kwarg[1] ∈ keys ? hits : others, kwarg)
    end
    return hits, others
end

# For compatibility.
if !isdefined(Base, :Cvoid)
    const Cvoid = Void
end

include("libz.jl")
include("compression.jl")
include("decompression.jl")

# Deprecations
# ------------

@deprecate GzipCompression            GzipCompressor
@deprecate GzipCompressionStream      GzipCompressorStream
@deprecate GzipDecompression          GzipDecompressor
@deprecate GzipDecompressionStream    GzipDecompressorStream
@deprecate ZlibCompression            ZlibCompressor
@deprecate ZlibCompressionStream      ZlibCompressorStream
@deprecate ZlibDecompression          ZlibDecompressor
@deprecate ZlibDecompressionStream    ZlibDecompressorStream
@deprecate DeflateCompression         DeflateCompressor
@deprecate DeflateCompressionStream   DeflateCompressorStream
@deprecate DeflateDecompression       DeflateDecompressor
@deprecate DeflateDecompressionStream DeflateDecompressorStream

end # module
