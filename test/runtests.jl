using CodecZlib
using Random
using Test
import TranscodingStreams:
    TranscodingStreams,
    TranscodingStream,
    test_roundtrip_read,
    test_roundtrip_write,
    test_roundtrip_lines,
    test_roundtrip_transcode

const testdir = @__DIR__

@testset "Gzip Codec" begin
    codec = GzipCompressor()
    @test codec isa GzipCompressor
    @test occursin(r"^(CodecZlib\.)?GzipCompressor\(level=-1, windowbits=\d+\)$", sprint(show, codec))
    @test CodecZlib.initialize(codec) === nothing
    @test CodecZlib.finalize(codec) === nothing

    codec = GzipDecompressor()
    @test codec isa GzipDecompressor
    @test occursin(r"^(CodecZlib\.)?GzipDecompressor\(windowbits=\d+\)$", sprint(show, codec))
    @test CodecZlib.initialize(codec) === nothing
    @test CodecZlib.finalize(codec) === nothing

    # `gzip.compress(b"foo")` in Python 3.6.2 (zlib 1.2.8).
    gzip_data = b"\x1f\x8b\x08\x00R\xcc\x10Y\x02\xffK\xcb\xcf\x07\x00!es\x8c\x03\x00\x00\x00"

    file = IOBuffer(gzip_data)
    stream = GzipDecompressorStream(file)
    @test !eof(stream)
    @test read(stream) == b"foo"
    @test eof(stream)
    @test close(stream) === nothing
    @test !isopen(stream)
    @test !isopen(file)

    file = IOBuffer(gzip_data)
    stream = GzipDecompressorStream(file, bufsize=1)
    @test length(stream.state.buffer1) == 1
    @test length(stream.state.buffer2) == 1
    @test read(stream) == b"foo"
    close(stream)

    # Corrupted data
    gzip_data_corrupted = copy(gzip_data)
    gzip_data_corrupted[1] = 0x00  # corrupt header
    file = IOBuffer(gzip_data_corrupted)
    stream = GzipDecompressorStream(file)
    @test_throws ErrorException read(stream)
    @test_throws ArgumentError read(stream)
    @test !isopen(stream)
    @test isopen(file)
    @test close(stream) === nothing
    @test !isopen(stream)
    @test !isopen(file)

    stream = TranscodingStream(GzipDecompressor(gziponly=false), IOBuffer(gzip_data))
    @test read(stream) == b"foo"
    close(stream)

    stream = TranscodingStream(GzipDecompressor(gziponly=true), IOBuffer(gzip_data))
    @test read(stream) == b"foo"
    close(stream)

    file = IOBuffer(vcat(gzip_data, gzip_data))
    stream = GzipDecompressorStream(file)
    @test read(stream) == b"foofoo"
    close(stream)

    open(joinpath(testdir, "foo.txt.gz")) do file
        @test read(GzipDecompressorStream(file)) == b"foo"
    end

    file = IOBuffer("foo")
    stream = GzipCompressorStream(file)
    @test !eof(stream)
    @test length(read(stream)) > 0
    @test eof(stream)
    @test close(stream) === nothing
    @test !isopen(stream)
    @test !isopen(file)

    mktemp() do path, file
        stream = GzipDecompressorStream(file)
        @test write(stream, gzip_data) == length(gzip_data)
        @test close(stream) === nothing
        @test !isopen(stream)
        @test !isopen(file)
        @test read(path) == b"foo"
    end

    mktemp() do path, file
        stream = GzipCompressorStream(file)
        @test write(stream, "foo") == 3
        @test close(stream) === nothing
        @test !isopen(stream)
        @test !isopen(file)
        @test length(read(path)) > 0
    end

    @test GzipCompressorStream <: TranscodingStream
    @test GzipDecompressorStream <: TranscodingStream

    test_roundtrip_read(GzipCompressorStream, GzipDecompressorStream)
    test_roundtrip_write(GzipCompressorStream, GzipDecompressorStream)
    test_roundtrip_lines(GzipCompressorStream, GzipDecompressorStream)
    test_roundtrip_transcode(GzipCompressor, GzipDecompressor)

    @test_throws ArgumentError GzipCompressor(level=10)
    @test_throws ArgumentError GzipCompressor(windowbits=16)
    @test_throws ArgumentError GzipDecompressor(windowbits=16)
end

@testset "Zlib Codec" begin
    codec = ZlibCompressor()
    @test codec isa ZlibCompressor
    @test occursin(r"^(CodecZlib\.)?ZlibCompressor\(level=-1, windowbits=\d+\)$", sprint(show, codec))
    @test CodecZlib.initialize(codec) === nothing
    @test CodecZlib.finalize(codec) === nothing

    codec = ZlibDecompressor()
    @test codec isa ZlibDecompressor
    @test occursin(r"^(CodecZlib\.)?ZlibDecompressor\(windowbits=\d+\)$", sprint(show, codec))
    @test CodecZlib.initialize(codec) === nothing
    @test CodecZlib.finalize(codec) === nothing

    # `zlib.compress(b"foo")` in Python 3.6.2 (zlib 1.2.8).
    zlib_data = b"x\x9cK\xcb\xcf\x07\x00\x02\x82\x01E"

    file = IOBuffer(zlib_data)
    stream = ZlibDecompressorStream(file)
    @test !eof(stream)
    @test read(stream) == b"foo"
    @test eof(stream)
    @test close(stream) === nothing
    @test !isopen(stream)
    @test !isopen(file)

    file = IOBuffer(zlib_data)
    stream = ZlibDecompressorStream(file, bufsize=1)
    @test length(stream.state.buffer1) == 1
    @test length(stream.state.buffer2) == 1
    @test read(stream) == b"foo"
    close(stream)

    stream = TranscodingStream(GzipDecompressor(gziponly=false), IOBuffer(zlib_data))
    @test read(stream) == b"foo"
    close(stream)

    stream = TranscodingStream(GzipDecompressor(gziponly=true), IOBuffer(zlib_data))
    @test_throws Exception read(stream)
    close(stream)

    file = IOBuffer(b"foo")
    stream = ZlibCompressorStream(file)
    @test !eof(stream)
    @test read(stream) == zlib_data
    @test eof(stream)
    @test close(stream) === nothing
    @test !isopen(stream)
    @test !isopen(file)

    mktemp() do path, file
        stream = ZlibDecompressorStream(file)
        @test write(stream, zlib_data) == length(zlib_data)
        @test close(stream) === nothing
        @test !isopen(stream)
        @test !isopen(file)
        @test read(path) == b"foo"
    end

    mktemp() do path, file
        stream = ZlibCompressorStream(file)
        @test write(stream, "foo") == 3
        @test close(stream) === nothing
        @test !isopen(stream)
        @test !isopen(file)
        @test read(path) == zlib_data
    end

    @test ZlibCompressorStream <: TranscodingStream
    @test ZlibDecompressorStream <: TranscodingStream

    test_roundtrip_read(ZlibCompressorStream, ZlibDecompressorStream)
    test_roundtrip_write(ZlibCompressorStream, ZlibDecompressorStream)
    test_roundtrip_lines(ZlibCompressorStream, ZlibDecompressorStream)
    test_roundtrip_transcode(ZlibCompressor, ZlibDecompressor)

    @test_throws ArgumentError ZlibCompressor(level=10)
    @test_throws ArgumentError ZlibCompressor(windowbits=16)
    @test_throws ArgumentError ZlibDecompressor(windowbits=16)
end

@testset "Deflate Codec" begin
    codec = DeflateCompressor()
    @test codec isa DeflateCompressor
    @test occursin(r"^(CodecZlib\.)?DeflateCompressor\(level=-1, windowbits=-\d+\)$", sprint(show, codec))
    @test CodecZlib.initialize(codec) === nothing
    # FIXME: This test fails.
    #@test CodecZlib.finalize(codec) === nothing

    codec = DeflateDecompressor()
    @test codec isa DeflateDecompressor
    @test occursin(r"^(CodecZlib\.)?DeflateDecompressor\(windowbits=-\d+\)$", sprint(show, codec))
    @test CodecZlib.initialize(codec) === nothing
    @test CodecZlib.finalize(codec) === nothing

    test_roundtrip_read(DeflateCompressorStream, DeflateDecompressorStream)
    test_roundtrip_write(DeflateCompressorStream, DeflateDecompressorStream)
    test_roundtrip_lines(DeflateCompressorStream, DeflateDecompressorStream)
    test_roundtrip_transcode(DeflateCompressor, DeflateDecompressor)

    @test DeflateCompressorStream <: TranscodingStream
    @test DeflateDecompressorStream <: TranscodingStream

    @test_throws ArgumentError DeflateCompressor(level=10)
    @test_throws ArgumentError DeflateCompressor(windowbits=16)
    @test_throws ArgumentError DeflateDecompressor(windowbits=16)
end

# Test APIs of TranscodingStreams.jl using the gzip compressor/decompressor.
@testset "TranscodingStreams" begin
    TranscodingStreams.test_chunked_read(GzipCompressor, GzipDecompressor)
    TranscodingStreams.test_chunked_write(GzipCompressor, GzipDecompressor)
    TranscodingStreams.test_roundtrip_fileio(GzipCompressor, GzipDecompressor)

    @testset "seek" begin
        data = transcode(GzipCompressor, Vector(b"abracadabra"))
        stream = TranscodingStream(GzipDecompressor(), IOBuffer(data))
        seekstart(stream)
        @test read(stream, 3) == b"abr"
        seekstart(stream)
        @test read(stream, 3) == b"abr"
    end

    @testset "panic" begin
        stream = TranscodingStream(GzipDecompressor(), IOBuffer("some invalid data"))
        @test_throws ErrorException read(stream)
        @test_throws ArgumentError eof(stream)
    end

    testfile = joinpath(dirname(@__FILE__), "abra.gz")

    @testset "open" begin
        open(GzipDecompressorStream, testfile) do stream
            @test read(stream) == b"abracadabra"
        end
    end

    @testset "stats" begin
        size = filesize(testfile)
        stream = GzipDecompressorStream(open(testfile))
        stats = TranscodingStreams.stats(stream)
        @test stats.in == 0
        @test stats.out == 0
        @test stats.transcoded_in == 0
        @test stats.transcoded_out == 0
        read(stream, UInt8)
        stats = TranscodingStreams.stats(stream)
        @test stats.in == size
        @test stats.out == 1
        @test stats.transcoded_in == size
        @test stats.transcoded_out == 11
        close(stream)
        @test_throws ArgumentError TranscodingStreams.stats(stream)

        buf = IOBuffer()
        stream = GzipCompressorStream(buf)
        stats = TranscodingStreams.stats(stream)
        @test stats.in == 0
        @test stats.out == 0
        @test stats.transcoded_in == 0
        @test stats.transcoded_out == 0
        write(stream, b"abracadabra")
        stats = TranscodingStreams.stats(stream)
        @test stats.in == 11
        @test stats.out == 0
        @test stats.transcoded_in == 0
        @test stats.transcoded_out == 0
        write(stream, TranscodingStreams.TOKEN_END)
        flush(stream)
        stats = TranscodingStreams.stats(stream)
        @test stats.in == 11
        @test stats.out == position(buf)
        @test stats.transcoded_in == 11
        @test stats.transcoded_out == position(buf)
        close(stream)
        @test_throws ArgumentError TranscodingStreams.stats(stream)
    end
end
