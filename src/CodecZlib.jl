module CodecZlib

export
    # gzip
    GzipInflation,
    GzipInflationStream,
    GzipDeflation,
    GzipDeflationStream,
    # zlib
    ZlibInflation,
    ZlibInflationStream,
    ZlibDeflation,
    ZlibDeflationStream,
    # raw
    RawInflation,
    RawInflationStream,
    RawDeflation,
    RawDeflationStream

import Libz
import TranscodingStreams:
    TranscodingStreams,
    Codec,
    ReadMode,
    WriteMode,
    ProcCode,
    PROC_OK,
    PROC_FINISH,
    TranscodingStream,
    process,
    finish

include("state.jl")
include("raw.jl")
include("zlib.jl")
include("gzip.jl")
include("inflation.jl")
include("deflation.jl")

end # module
