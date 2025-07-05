.PHONY: all build test release clean benchmark

all: build

build:
	zig build

release:
	zig build --release=fast

test:
	zig build test

clean:
	rm -rdf ./zig-out ./zig-cache

benchmark: release
	./scripts/benchmark.sh
