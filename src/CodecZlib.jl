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
using Libdl

const libzpath = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if !isfile(libzpath)
    error("CodecZlib.jl is not installed properly, run Pkg.build(\"CodecZlib\") and restart Julia.")
end
include(libzpath)
check_deps()

include("libz.jl")
include("compression.jl")
include("decompression.jl")

end # module
