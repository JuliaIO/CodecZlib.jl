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

    # raw
    RawCompression,
    RawCompressionStream,
    RawDecompression,
    RawDecompressionStream

import TranscodingStreams:
    TranscodingStreams,
    TranscodingStream,
    Memory

include("libz.jl")
include("compression.jl")
include("decompression.jl")

end # module
