# CodecZlib.jl

<!--[![Docs Latest][docs-latest-img]][docs-latest-url]-->
<!--[![Appveyor Status][appveyor-img]][appveyor-url]-->
[![TravisCI Status][travisci-img]][travisci-url]
[![codecov.io][codecov-img]][codecov-url]

This package exports following codecs and streams:

| Codec                  | Stream                       |
| ---------------------- | ---------------------------- |
| `GzipCompression`      | `GzipCompressionStream`      |
| `GzipDecompression`    | `GzipDecompressionStream`    |
| `ZlibCompression`      | `ZlibCompressionStream`      |
| `ZlibDecompression`    | `ZlibDecompressionStream`    |
| `DeflateCompression`   | `DeflateCompressionStream`   |
| `DeflateDecompression` | `DeflateDecompressionStream` |

See docstrings and [TranscodingStreams.jl](https://github.com/bicycle1885/TranscodingStreams.jl) for details.

[travisci-img]: https://travis-ci.org/bicycle1885/CodecZlib.jl.svg?branch=master
[travisci-url]: https://travis-ci.org/bicycle1885/CodecZlib.jl
[codecov-img]: http://codecov.io/github/bicycle1885/CodecZlib.jl/coverage.svg?branch=master
[codecov-url]: http://codecov.io/github/bicycle1885/CodecZlib.jl?branch=master
