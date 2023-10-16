const std = @import("std");
const Allocator = std.mem.Allocator;
const Random = std.rand.Random;
const DefaultPrng = std.rand.DefaultPrng;
const zkwargs = @import("zkwargs");

pub fn shuffle(rand: Random, data: anytype, _kwargs: anytype) ShuffleRtnT(@TypeOf(data[0]), @TypeOf(_kwargs)) {
    const kwargs = zkwargs.Options(ShuffleOpt).parse(_kwargs);
    const T = @TypeOf(data[0]);
    if (comptime @hasField(@TypeOf(kwargs), "allocator")) {
        // Problem tends to be bandwidth-limited and behaves poorly with
        // parallel approaches. Our general strategy is to do a fischer-
        // yates shuffle on _something_, and when there would be significant
        // bandwidth savings that something is a set of indices from 0..n-1,
        // which we use to fill a result buffer.
        //
        // For small types this results in around 2n writes, asymptotically
        // approaching n writes for shuffles of slices of large types.
        if (indices_fit_in(data, u16) and comptime external_array_saves_bandwidth(T, u16)) {
            return idx_shuffle(kwargs.allocator, rand, data, u16);
        }
        if (indices_fit_in(data, u32) and comptime external_array_saves_bandwidth(T, u32)) {
            return idx_shuffle(kwargs.allocator, rand, data, u32);
        }
        if (comptime external_array_saves_bandwidth(T, usize)) {
            return idx_shuffle(kwargs.allocator, rand, data, usize);
        }
        return copy_shuffle(kwargs.allocator, rand, data);
    } else {
        rand.shuffle(T, data);
    }
}

fn copy_shuffle(allocator: Allocator, rand: Random, data: anytype) ![]@TypeOf(data[0]) {
    var rtn = try allocator.alloc(@TypeOf(data[0]), data.len);
    for (rtn, 0..) |*x, i|
        x.* = data[i];
    rand.shuffle(@TypeOf(data[0]), rtn);
    return rtn;
}

fn idx_shuffle(allocator: Allocator, rand: Random, data: anytype, comptime IdxT: type) ![]@TypeOf(data[0]) {
    var rtn = try allocator.alloc(@TypeOf(data[0]), data.len);
    errdefer allocator.free(rtn);
    var intermediate = try allocator.alloc(IdxT, data.len);
    defer allocator.free(intermediate);
    for (intermediate, 0..) |*x, i|
        x.* = @intCast(i);
    rand.shuffle(IdxT, intermediate);
    for (rtn, 0..) |*x, i|
        x.* = data[@intCast(intermediate[i])];
    return rtn;
}

const ShuffleOpt = struct {
    pub fn allocator(comptime MaybeT: ?type) ?type {
        zkwargs.allowed_types(MaybeT, "allocator", .{Allocator});
        return null;
    }
};

fn ShuffleRtnT(comptime DataT: type, comptime KwargsT: type) type {
    const kwargs = zkwargs.Options(ShuffleOpt).parse(@as(KwargsT, undefined));
    if (@hasField(@TypeOf(kwargs), "allocator")) {
        return Allocator.Error![]DataT;
    } else {
        return void;
    }
}

inline fn indices_fit_in(data: anytype, comptime T: type) bool {
    return data.len == 0 or data.len - 1 <= std.math.maxInt(T);
}

inline fn external_array_saves_bandwidth(comptime DataT: type, comptime IdxT: type) bool {
    // +1 DataT: copy to result buffer
    // +2 DataT: in-place fischer
    const copy_cost = @sizeOf(DataT) * 3;

    // +1 IdxT: populate indices
    // +2 IdxT: in-place fischer
    // +1 DataT: copy to result buffer
    const idx_cost = @sizeOf(IdxT) * 3 + @sizeOf(DataT);

    return idx_cost > copy_cost;
}

test "doesn't crash" {
    std.debug.print("\n", .{});
    const allocator = std.testing.allocator;
    var ri = DefaultPrng.init(42);
    var rand = ri.random();
    var data = try allocator.alloc(f64, 10000);
    defer allocator.free(data);
    shuffle(rand, data, .{});
    allocator.free(try shuffle(rand, data, .{ .allocator = allocator }));
}
