CodecZlib.jl
============

[![CI](https://github.com/JuliaIO/CodecZlib.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/JuliaIO/CodecZlib.jl/actions/workflows/CI.yml)
[![codecov](https://codecov.io/gh/JuliaIO/CodecZlib.jl/graph/badge.svg?token=6V3Z847Ywr)](https://codecov.io/gh/JuliaIO/CodecZlib.jl)

## Installation

```julia
Pkg.add("CodecZlib")
```

## Usage

```julia
using CodecZlib

# Some text.
text = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean sollicitudin
mauris non nisi consectetur, a dapibus urna pretium. Vestibulum non posuere
erat. Donec luctus a turpis eget aliquet. Cras tristique iaculis ex, eu
malesuada sem interdum sed. Vestibulum ante ipsum primis in faucibus orci luctus
et ultrices posuere cubilia Curae; Etiam volutpat, risus nec gravida ultricies,
erat ex bibendum ipsum, sed varius ipsum ipsum vitae dui.
"""

# Streaming API.
stream = GzipCompressorStream(IOBuffer(text))
for line in eachline(GzipDecompressorStream(stream))
    println(line)
end
close(stream)

# Array API.
compressed = transcode(GzipCompressor, text)
@assert sizeof(compressed) < sizeof(text)
@assert transcode(GzipDecompressor, compressed) == Vector{UInt8}(text)
```

### Concatenated and embedded streams

By default, decompressors process concatenated compressed streams. Bytes after
the end of a stream are therefore interpreted as the start of another stream,
and invalid trailing data raises a `ZlibError`.

When a compressed stream is embedded in a larger format, set `stop_on_end=true`
to stop after the first stream:

```julia
stream = ZlibDecompressorStream(IOBuffer(compressed_data); stop_on_end=true)
data = read(stream)
close(stream)
```

To preserve and read bytes following the compressed stream, wrap the input in a
`NoopStream`. This shares the buffering between streams so that bytes read
ahead by the decompressor remain available:

```julia
using TranscodingStreams: NoopStream

input = NoopStream(IOBuffer(compressed_data_with_trailing_bytes))
stream = ZlibDecompressorStream(input; stop_on_end=true)
data = read(stream)
close(stream)
trailing_bytes = read(input)
close(input)
```

This package exports following codecs and streams:

| Codec                  | Stream                       |
| ---------------------- | ---------------------------- |
| `GzipCompressor`       | `GzipCompressorStream`       |
| `GzipDecompressor`     | `GzipDecompressorStream`     |
| `ZlibCompressor`       | `ZlibCompressorStream`       |
| `ZlibDecompressor`     | `ZlibDecompressorStream`     |
| `DeflateCompressor`    | `DeflateCompressorStream`    |
| `DeflateDecompressor`  | `DeflateDecompressorStream`  |

See docstrings and [TranscodingStreams.jl](https://github.com/JuliaIO/TranscodingStreams.jl) for details.
