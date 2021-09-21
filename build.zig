const std = @import("std");
const autopkg = @import("autopkg/autopkg.zig");

pub const PackageConfig = struct {
    skipTest: bool = true,
    useBundledSQLite: bool = true,
};

pub fn package(name: []const u8, path: []const u8, comptime conf: PackageConfig) autopkg.AutoPkgI {
    return autopkg.genExport(.{
        .name = name,
        .path = path,
        .rootSrc = "sqlite.zig",
        .cSrcFiles = if (conf.useBundledSQLite) &.{"c/sqlite3.c"} else &.{},
        .includeDirs = if (conf.useBundledSQLite) &.{"c/"} else &.{},
        .doNotTest = conf.skipTest,
        .testSrcs = &.{
            "query.zig",
            "errors.zig",
        },
        .linkSystemLibs = if (!conf.useBundledSQLite) &.{"sqlite3"} else &.{},
        .ccflags = &.{"-Wall", "-std=gnu99", "-g"},
        .linkLibC = true,
    });
}

pub fn build(b: *std.build.Builder) !void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});

    var myPackage = autopkg.accept(package("sqlite", ".", .{
        .skipTest = false,
        .useBundledSQLite = true,
    }));
    defer myPackage.deinit();

    var resolvedPackage = try myPackage.resolve(".", b.allocator);

    var staticLib = resolvedPackage.addBuild(b);
    staticLib.setBuildMode(mode);
    staticLib.setTarget(target);
    staticLib.install();

    var packageTests = resolvedPackage.addTest(b, mode, &target);
    const testStep = b.step("test", "Run library tests");
    testStep.dependOn(packageTests);
}
