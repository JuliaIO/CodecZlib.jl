using CodecZlib
using Base.Test
import TranscodingStreams:
    TranscodingStream,
    test_roundtrip_read,
    test_roundtrip_write,
    test_roundtrip_lines,
    test_roundtrip_transcode

const testdir = @__DIR__

@testset "Gzip Codec" begin
    codec = GzipCompression()
    @test codec isa GzipCompression
    @test ismatch(r"^CodecZlib.GzipCompression\(level=-1, windowbits=\d+\)$", sprint(show, codec))
    @test CodecZlib.initialize(codec) === nothing
    @test CodecZlib.finalize(codec) === nothing

    codec = GzipDecompression()
    @test codec isa GzipDecompression
    @test ismatch(r"^CodecZlib.GzipDecompression\(windowbits=\d+\)$", sprint(show, codec))
    @test CodecZlib.initialize(codec) === nothing
    @test CodecZlib.finalize(codec) === nothing

    # `gzip.compress(b"foo")` in Python 3.6.2 (zlib 1.2.8).
    gzip_data = b"\x1f\x8b\x08\x00R\xcc\x10Y\x02\xffK\xcb\xcf\x07\x00!es\x8c\x03\x00\x00\x00"

    file = IOBuffer(gzip_data)
    stream = GzipDecompressionStream(file)
    @test !eof(stream)
    @test read(stream) == b"foo"
    @test eof(stream)
    @test close(stream) === nothing
    @test !isopen(stream)
    @test !isopen(file)

    # Corrupted data
    gzip_data_corrupted = copy(gzip_data)
    gzip_data_corrupted[1] = 0x00  # corrupt header
    file = IOBuffer(gzip_data_corrupted)
    stream = GzipDecompressionStream(file)
    @test_throws ErrorException read(stream)
    @test_throws ArgumentError read(stream)
    @test !isopen(stream)
    @test isopen(file)
    @test close(stream) === nothing
    @test !isopen(stream)
    @test !isopen(file)

    stream = TranscodingStream(GzipDecompression(gziponly=false), IOBuffer(gzip_data))
    @test read(stream) == b"foo"
    close(stream)

    stream = TranscodingStream(GzipDecompression(gziponly=true), IOBuffer(gzip_data))
    @test read(stream) == b"foo"
    close(stream)

    file = IOBuffer(vcat(gzip_data, gzip_data))
    stream = GzipDecompressionStream(file)
    @test read(stream) == b"foofoo"
    close(stream)

    open(joinpath(testdir, "foo.txt.gz")) do file
        @test read(GzipDecompressionStream(file)) == b"foo"
    end

    file = IOBuffer("foo")
    stream = GzipCompressionStream(file)
    @test !eof(stream)
    @test length(read(stream)) > 0
    @test eof(stream)
    @test close(stream) === nothing
    @test !isopen(stream)
    @test !isopen(file)

    mktemp() do path, file
        stream = GzipDecompressionStream(file)
        @test write(stream, gzip_data) == length(gzip_data)
        @test close(stream) === nothing
        @test !isopen(stream)
        @test !isopen(file)
        @test read(path) == b"foo"
    end

    mktemp() do path, file
        stream = GzipCompressionStream(file)
        @test write(stream, "foo") == 3
        @test close(stream) === nothing
        @test !isopen(stream)
        @test !isopen(file)
        @test length(read(path)) > 0
    end

    @test GzipCompressionStream <: TranscodingStream
    @test GzipDecompressionStream <: TranscodingStream

    test_roundtrip_read(GzipCompressionStream, GzipDecompressionStream)
    test_roundtrip_write(GzipCompressionStream, GzipDecompressionStream)
    test_roundtrip_lines(GzipCompressionStream, GzipDecompressionStream)
    test_roundtrip_transcode(GzipCompression, GzipDecompression)

    @test_throws ArgumentError GzipCompression(level=10)
    @test_throws ArgumentError GzipCompression(windowbits=16)
    @test_throws ArgumentError GzipDecompression(windowbits=16)
end

@testset "Zlib Codec" begin
    codec = ZlibCompression()
    @test codec isa ZlibCompression
    @test ismatch(r"^CodecZlib\.ZlibCompression\(level=-1, windowbits=\d+\)$", sprint(show, codec))
    @test CodecZlib.initialize(codec) === nothing
    @test CodecZlib.finalize(codec) === nothing

    codec = ZlibDecompression()
    @test codec isa ZlibDecompression
    @test ismatch(r"^CodecZlib\.ZlibDecompression\(windowbits=\d+\)$", sprint(show, codec))
    @test CodecZlib.initialize(codec) === nothing
    @test CodecZlib.finalize(codec) === nothing

    # `zlib.compress(b"foo")` in Python 3.6.2 (zlib 1.2.8).
    zlib_data = b"x\x9cK\xcb\xcf\x07\x00\x02\x82\x01E"

    file = IOBuffer(zlib_data)
    stream = ZlibDecompressionStream(file)
    @test !eof(stream)
    @test read(stream) == b"foo"
    @test eof(stream)
    @test close(stream) === nothing
    @test !isopen(stream)
    @test !isopen(file)

    stream = TranscodingStream(GzipDecompression(gziponly=false), IOBuffer(zlib_data))
    @test read(stream) == b"foo"
    close(stream)

    stream = TranscodingStream(GzipDecompression(gziponly=true), IOBuffer(zlib_data))
    @test_throws Exception read(stream)
    close(stream)

    file = IOBuffer(b"foo")
    stream = ZlibCompressionStream(file)
    @test !eof(stream)
    @test read(stream) == zlib_data
    @test eof(stream)
    @test close(stream) === nothing
    @test !isopen(stream)
    @test !isopen(file)

    mktemp() do path, file
        stream = ZlibDecompressionStream(file)
        @test write(stream, zlib_data) == length(zlib_data)
        @test close(stream) === nothing
        @test !isopen(stream)
        @test !isopen(file)
        @test read(path) == b"foo"
    end

    mktemp() do path, file
        stream = ZlibCompressionStream(file)
        @test write(stream, "foo") == 3
        @test close(stream) === nothing
        @test !isopen(stream)
        @test !isopen(file)
        @test read(path) == zlib_data
    end

    @test ZlibCompressionStream <: TranscodingStream
    @test ZlibDecompressionStream <: TranscodingStream

    test_roundtrip_read(ZlibCompressionStream, ZlibDecompressionStream)
    test_roundtrip_write(ZlibCompressionStream, ZlibDecompressionStream)
    test_roundtrip_lines(ZlibCompressionStream, ZlibDecompressionStream)
    test_roundtrip_transcode(ZlibCompression, ZlibDecompression)

    @test_throws ArgumentError ZlibCompression(level=10)
    @test_throws ArgumentError ZlibCompression(windowbits=16)
    @test_throws ArgumentError ZlibDecompression(windowbits=16)
end

@testset "Deflate Codec" begin
    codec = DeflateCompression()
    @test codec isa DeflateCompression
    @test ismatch(r"^CodecZlib\.DeflateCompression\(level=-1, windowbits=-\d+\)$", sprint(show, codec))
    @test CodecZlib.initialize(codec) === nothing
    # FIXME: This test fails.
    #@test CodecZlib.finalize(codec) === nothing

    codec = DeflateDecompression()
    @test codec isa DeflateDecompression
    @test ismatch(r"^CodecZlib\.DeflateDecompression\(windowbits=-\d+\)$", sprint(show, codec))
    @test CodecZlib.initialize(codec) === nothing
    @test CodecZlib.finalize(codec) === nothing

    test_roundtrip_read(DeflateCompressionStream, DeflateDecompressionStream)
    test_roundtrip_write(DeflateCompressionStream, DeflateDecompressionStream)
    test_roundtrip_lines(DeflateCompressionStream, DeflateDecompressionStream)
    test_roundtrip_transcode(DeflateCompression, DeflateDecompression)

    @test DeflateCompressionStream <: TranscodingStream
    @test DeflateDecompressionStream <: TranscodingStream

    @test_throws ArgumentError DeflateCompression(level=10)
    @test_throws ArgumentError DeflateCompression(windowbits=16)
    @test_throws ArgumentError DeflateDecompression(windowbits=16)
end
