//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Basics
import PackageModel
import class TSCBasic.Process
import func TSCBasic.withTemporaryDirectory

public enum ClangSupport {
    private static var flagsMap = ThreadSafeBox<[String: [String]]>()

    public static func checkCompilerFlags(
        flags: [String],
        toolchain: PackageModel.Toolchain,
        triple: Triple,
        fileSystem: FileSystem
    ) throws -> Bool {
        let clangPath = try toolchain.getClangCompiler().pathString
        if let entry = flagsMap.get(), let cachedSupportedFlags = entry[clangPath] {
            return cachedSupportedFlags.firstIndex(of: flags) != nil
        }
        let extraFlags: [String]
        if triple.isDarwin(), let sdkRootPath = toolchain.sdkRootPath {
            extraFlags = ["-isysroot", sdkRootPath.pathString]
        } else {
            extraFlags = []
        }
        do {
            try withTemporaryDirectory { tmpPath in
                let inputPath = tmpPath.appending(component: "foo.c")
                try localFileSystem.writeFileContents(inputPath, string: "int main() {\nreturn 0;\n}")
                let outputPath = tmpPath.appending("foo")
                try Process.checkNonZeroExit(arguments: [
                    clangPath,
                    inputPath.pathString,
                    "-o",
                    outputPath.pathString
                ] + extraFlags + flags, environment: [:])
                try Process.checkNonZeroExit(arguments: [outputPath.pathString])
            }
        } catch {
            return false
        }
        // Note: the cache only supports a single list of flags being checked.
        flagsMap.put([clangPath: flags])
        return true
    }
}
