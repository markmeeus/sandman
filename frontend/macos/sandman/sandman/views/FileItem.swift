//
//  FileItem.swift
//  sandman
//
//  Created by Mark Meeus on 02/09/2025.
//

import Foundation

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var url: URL
    var isDirectory: Bool
    var isHidden: Bool
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

            // Preserve existing items where possible to maintain IDs and state
            let existingChildren = children ?? []
            var newChildren: [FileItem] = []

            for contentURL in contents {
                // Try to find existing item with same URL
                if let existingItem = existingChildren.first(where: { $0.url == contentURL }) {
                    var updatedItem = existingItem
                    updatedItem.refreshFromFileSystem()
                    newChildren.append(updatedItem)
                } else {
                    // Create new item if it doesn't exist
                    newChildren.append(FileItem(url: contentURL))
                }
            }

            self.children = newChildren.sorted { lhs, rhs in
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

    mutating func refreshFromFileSystem() {
        // Update properties from current file system state
        self.name = url.lastPathComponent
        self.isHidden = name.hasPrefix(".")

        // Update directory status
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        self.isDirectory = exists && isDir.boolValue

        // Note: We don't reload children here to avoid infinite recursion
        // Children will be reloaded when loadChildren() is called explicitly
    }
}
