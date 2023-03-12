# zshuffle

write-minimizing fischer-yates shuffle

## Purpose

Shuffling large amounts of data is mostly bandwidth-bound. When the individual element types are large there's a roughly 2x savings to be had by applying a naive fischer-yates shuffle on indices 0..n-1 and then using that to read into a result buffer. This library just packs that up into a simple API.

## Installation

Copy-paste or [git-subrepo](https://github.com/ingydotnet/git-subrepo) or whatever. Also, ZIG HAS A PACKAGE MANAGER NOW!!! Use it with something like the following.

```zig
// build.zig.zon
.{
    .name = "foo",
    .version = "0.0.0",
    .dependencies = .{
        .zshuffle = .{
	   .url = "https://github.com/hmusgrave/zshuffle/archive/refs/tags/z11-0.0.1.tar.gz",
            .hash = "12207b3b8d84848638c2561e5fc9f84bd3e48a6f8139b40e18430f967c4e26c142ec",
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
