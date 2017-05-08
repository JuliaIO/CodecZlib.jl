using CodecZlib
using Base.Test

const testdir = dirname(@__FILE__)

@testset "Gzip" begin
    # `gzip.compress(b"foo")` in Python 3.6.2 (zlib 1.2.8).
    gzip_data = b"\x1f\x8b\x08\x00R\xcc\x10Y\x02\xffK\xcb\xcf\x07\x00!es\x8c\x03\x00\x00\x00"

    file = IOBuffer(gzip_data)
    stream = GzipInflationStream(file)
    @test !eof(stream)
    @test read(stream) == b"foo"
    @test eof(stream)
    @test close(stream) === nothing
    @test !isopen(stream)
    @test !isopen(file)

    open(joinpath(testdir, "foo.txt.gz")) do file
        @test read(GzipInflationStream(file)) == b"foo"
    end

    file = IOBuffer("foo")
    stream = GzipDeflationStream(file)
    @test !eof(stream)
    @test length(read(stream)) > 0
    @test eof(stream)
    @test close(stream) === nothing
    @test !isopen(stream)
    @test !isopen(file)

    @testset "small data" for n in 0:30
        # high entropy
        data = rand(UInt8, n)
        file = IOBuffer(data)
        stream = GzipInflationStream(GzipDeflationStream(file))
        @test read(stream) == data

        # low entropy
        data = rand(0x00:0x0f, n)
        file = IOBuffer(data)
        stream = GzipInflationStream(GzipDeflationStream(file))
        @test read(stream) == data
    end

    @testset "large data" for n in [500, 1000, 5_000, 10_000]
        # high entropy
        data = rand(UInt8, n)
        file = IOBuffer(data)
        stream = GzipInflationStream(GzipDeflationStream(file))
        @test read(stream) == data

        # low entropy
        data = rand(0x00:0x0f, n)
        file = IOBuffer(data)
        stream = GzipInflationStream(GzipDeflationStream(file))
        @test read(stream) == data
    end

    mktemp() do path, file
        stream = GzipInflationStream(file)
        @test write(stream, gzip_data) == length(gzip_data)
        @test close(stream) === nothing
        @test !isopen(stream)
        @test !isopen(file)
        @test read(path) == b"foo"
    end

    mktemp() do path, file
        stream = GzipDeflationStream(file)
        @test write(stream, "foo") == 3
        @test close(stream) === nothing
        @test !isopen(stream)
        @test !isopen(file)
        @test length(read(path)) > 0
    end
end

@testset "Zlib" begin
    # `zlib.compress(b"foo")` in Python 3.6.2 (zlib 1.2.8).
    zlib_data = b"x\x9cK\xcb\xcf\x07\x00\x02\x82\x01E"

    file = IOBuffer(zlib_data)
    stream = ZlibInflationStream(file)
    @test !eof(stream)
    @test read(stream) == b"foo"
    @test eof(stream)
    @test close(stream) === nothing
    @test !isopen(stream)
    @test !isopen(file)

    file = IOBuffer(b"foo")
    stream = ZlibDeflationStream(file)
    @test !eof(stream)
    @test read(stream) == zlib_data
    @test eof(stream)
    @test close(stream) === nothing
    @test !isopen(stream)
    @test !isopen(file)

    @testset "small data" for n in 0:30
        # high entropy
        data = rand(UInt8, n)
        file = IOBuffer(data)
        stream = ZlibInflationStream(ZlibDeflationStream(file))
        @test read(stream) == data

        # low entropy
        data = rand(0x00:0x0f, n)
        file = IOBuffer(data)
        stream = ZlibInflationStream(ZlibDeflationStream(file))
        @test read(stream) == data
    end

    @testset "large data" for n in [500, 1000, 5_000, 10_000]
        # high entropy
        data = rand(UInt8, n)
        file = IOBuffer(data)
        stream = ZlibInflationStream(ZlibDeflationStream(file))
        @test read(stream) == data

        # low entropy
        data = rand(0x00:0x0f, n)
        file = IOBuffer(data)
        stream = ZlibInflationStream(ZlibDeflationStream(file))
        @test read(stream) == data
    end

    mktemp() do path, file
        stream = ZlibInflationStream(file)
        @test write(stream, zlib_data) == length(zlib_data)
        @test close(stream) === nothing
        @test !isopen(stream)
        @test !isopen(file)
        @test read(path) == b"foo"
    end

    mktemp() do path, file
        stream = ZlibDeflationStream(file)
        @test write(stream, "foo") == 3
        @test close(stream) === nothing
        @test !isopen(stream)
        @test !isopen(file)
        @test read(path) == zlib_data
    end
end

@testset "Raw" begin
    @testset "small data" for n in 0:30
        # high entropy
        data = rand(UInt8, n)
        file = IOBuffer(data)
        stream = RawInflationStream(RawDeflationStream(file))
        @test read(stream) == data

        # low entropy
        data = rand(0x00:0x0f, n)
        file = IOBuffer(data)
        stream = RawInflationStream(RawDeflationStream(file))
        @test read(stream) == data
    end
end
