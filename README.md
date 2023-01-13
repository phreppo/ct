# CounT

The fastest line counter our there.

## Building

I am using Zig version `0.11.0-dev.1278+4971df857`.
I think any commit in version `0.11` is fine to compile the project.
I would not use Zig < `0.11`.

```bash
# This produces a fast executable. Use this for benchmarking.
zig build -Dprofile-release
```