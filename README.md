# zshuffle

write-minimizing fischer-yates shuffle

## Purpose

Shuffling large amounts of data is mostly bandwidth-bound. When the individual element types are large there's a roughly 2x savings to be had by applying a naive fischer-yates shuffle on indices 0..n-1 and then using that to read into a result buffer. This library just packs that up into a simple API.

## Installation

Choose your favorite method for vendoring this code into your repository. I've been using [zigmod](https://github.com/nektro/zigmod) to lately, and it's pretty painless. I also generally like [git-subrepo](https://github.com/ingydotnet/git-subrepo), copy-paste is always a winner, and whenever the official package manager is up we'll be there too.

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
for (data) |*x,i|
    x.* = i;

// You can shuffle it in-place
shuffle(rand, data, .{});

// Or else you can shuffle into a new result buffer
var shuffled = try shuffle(rand, data, .{.allocator = allocator});
defer allocator.free(shuffled);
```
