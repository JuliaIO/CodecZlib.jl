VERSION < v"0.7.0-beta2.199" && __precompile__()

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
using Compat.Libdl

const libzpath = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if !isfile(libzpath)
    error("CodecZlib.jl is not installed properly, run Pkg.build(\"CodecZlib\") and restart Julia.")
end
include(libzpath)
check_deps()

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
