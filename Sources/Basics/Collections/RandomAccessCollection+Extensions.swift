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

// Since 'contains' is only available in macOS SDKs 13.0 or newer, we need our own little implementation.
extension RandomAccessCollection where Element: Equatable {
    public func firstIndex(of pattern: some RandomAccessCollection<Element>) -> Index? {
        guard !pattern.isEmpty && count >= pattern.count else {
            return nil
        }

        var i = startIndex
        for _ in 0..<(count - pattern.count + 1) {
            if self[i...].starts(with: pattern) {
                return i
            }
            i = self.index(after: i)
        }
        return nil
    }
}
