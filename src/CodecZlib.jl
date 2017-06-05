__precompile__()

module CodecZlib

export
    # gzip
    GzipCompression,
    GzipCompressionStream,
    GzipDecompression,
    GzipDecompressionStream,

    # zlib
    ZlibCompression,
    ZlibCompressionStream,
    ZlibDecompression,
    ZlibDecompressionStream,

    # deflate
    DeflateCompression,
    DeflateCompressionStream,
    DeflateDecompression,
    DeflateDecompressionStream

import TranscodingStreams:
    TranscodingStreams,
    TranscodingStream,
    Memory

include("libz.jl")
include("compression.jl")
include("decompression.jl")

end # module
