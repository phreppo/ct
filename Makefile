.PHONY: all build test release clean benchmark

all: build

build:
	zig build

release:
	zig build -Doptimize=ReleaseFast

test:
	zig build test

clean:
	rm -rdf ./zig-out ./zig-cache

benchmark: release
	./scripts/benchmark.sh
