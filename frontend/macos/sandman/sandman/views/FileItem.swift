//
//  FileItem.swift
//  sandman
//
//  Created by Mark Meeus on 02/09/2025.
//

import Foundation

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: URL
    let isDirectory: Bool
    let isHidden: Bool
    var children: [FileItem]?

    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        self.isHidden = name.hasPrefix(".")

        // Simple directory detection - no sandbox restrictions
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        self.isDirectory = exists && isDir.boolValue

        if isDirectory {
            self.children = []
        }
    }

    mutating func loadChildren() {
        guard isDirectory else { return }

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey],
                options: [.skipsHiddenFiles]
            )

            self.children = contents
                .map { FileItem(url: $0) }
                .sorted { lhs, rhs in
                    if lhs.isDirectory != rhs.isDirectory {
                        return lhs.isDirectory
                    }
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
        } catch {
            print("Error loading directory contents: \(error)")
            self.children = []
        }
    }

    var hasChildren: Bool {
        return isDirectory && !(children?.isEmpty ?? true)
    }
}
