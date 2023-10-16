# zshuffle

write-minimizing fischer-yates shuffle

## Purpose

Shuffling large amounts of data is mostly bandwidth-bound. When the individual element types are large there's a roughly 2x savings to be had by applying a naive fischer-yates shuffle on indices 0..n-1 and then using that to read into a result buffer. This library just packs that up into a simple API.

## Installation

```zig
// build.zig.zon
.{
    .name = "foo",
    .version = "0.0.0",
    .dependencies = .{
        .zshuffle = .{
            .url = "https://github.com/hmusgrave/zshuffle/archive/7cc5d08a8dc849b22078d4cff728e0859941af3d.tar.gz",
            .hash = "1220416f31bac21c9f69c2493110064324b2ba9e0257ce0db16fb4f94657124d7f39",
        },
    },
}
```

```zig
// build.zig
const zshuffle_pkg = b.dependency("zshuffle", .{
    .target = target,
    .optimize = optimize,
});
const zshuffle_mod = zshuffle_pkg.module("zshuffle");
exe.addModule("zshuffle", zshuffle_mod);
exe_tests.addModule("zshuffle", zshuffle_mod);
```

## Examples

```zig
const shuffle = @import("zshuffle").shuffle;

// We need a random number generator
var ri = std.random.DefaultPrng.init(42);
var rand = ri.random();

// And an allocator
const allocator = std.testing.allocator;

// Generate some data to shuffle
var data = allocator.alloc(usize, 1234);
defer allocator.free(data);
for (data) |*x,i|
    x.* = i;

// You can shuffle it in-place
shuffle(rand, data, .{});

// Or else you can shuffle into a new result buffer
var shuffled = try shuffle(rand, data, .{.allocator = allocator});
defer allocator.free(shuffled);
```

## Status
Working and builds for Zig 0.11 and 0.12. There isn't much in the way of marketing or other niceties other than this README and reading the source (there also isn't much source, so that ought to be easy).
