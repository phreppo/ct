.PHONY: all build test benchmark clean

all: build

build:
	zig build -Doptimize=ReleaseFast

test:
	zig build test -Doptimize=ReleaseFast

clean:
	rm -rdf ./zig-out ./zig-cache

benchmark: build
	./scripts/benchmark.sh
