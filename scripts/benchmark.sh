#/bin/bash
hyperfine --warmup 5 'wc -l files/16Gb' 'cw -l files/16Gb' './zig-out/bin/ct files/16Gb' --export-markdown results-singlethreded.md
hyperfine --warmup 5 'wc -l files/16Gb' 'cw -l --threads 4 files/16Gb' './zig-out/bin/ct --threads 4 files/16Gb' --export-markdown results-multithreaded-unfair.md
hyperfine --warmup 5 'wc -l files/16Gb files/16Gb files/16Gb files/16Gb' 'cw -l --threads 4 files/16Gb files/16Gb files/16Gb files/16Gb' './zig-out/bin/ct --threads 4 files/16Gb files/16Gb files/16Gb files/16Gb' --export-markdown results-multithreaded.md
hyperfine --warmup 5 './zig-out/bin/ct --threads 1 files/16Gb' './zig-out/bin/ct --threads 2 files/16Gb' './zig-out/bin/ct --threads 4 files/16Gb' './zig-out/bin/ct --threads 8 files/16Gb' --export-markdown results-scalability.md