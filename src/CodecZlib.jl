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

include("libz.jl")
include("compression.jl")
include("decompression.jl")

end # module
