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
    finalize,
    splitkwargs

using Compat: Cvoid

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
