//
//  FileBrowserView.swift
//  sandman
//
//  Created by Mark Meeus on 02/09/2025.
//

import SwiftUI

struct FileBrowserView: View {
    @State private var rootItem: FileItem
    @State private var expandedItems: Set<URL> = []
    @Binding var selectedFile: URL?

    init(rootURL: URL, selectedFile: Binding<URL?>) {
        self._selectedFile = selectedFile
        var rootFileItem = FileItem(url: rootURL)
        rootFileItem.loadChildren()
        self._rootItem = State(initialValue: rootFileItem)
    }

    // Convenience initializer for backward compatibility
    init(selectedFile: Binding<URL?>) {
        self.init(rootURL: FileManager.default.homeDirectoryForCurrentUser, selectedFile: selectedFile)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Files")
                .font(.headline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    FileItemView(
                        item: rootItem,
                        level: 0,
                        expandedItems: $expandedItems,
                        selectedFile: $selectedFile,
                        onRefreshNeeded: {
                            // Only refresh the root directory's children if they're loaded
                            if rootItem.children != nil {
                                rootItem.loadChildren()
                            }
                        }
                    )
                }
                .padding(.horizontal, 4)
            }
        }
        .frame(minWidth: 200)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct FileItemView: View {
    @State var item: FileItem
    let level: Int
    @Binding var expandedItems: Set<URL>
    @Binding var selectedFile: URL?
    let onRefreshNeeded: () -> Void

    @State private var showingNewFileAlert = false
    @State private var showingNewFolderAlert = false
    @State private var showingRenameAlert = false
    @State private var newItemName = ""
    @State private var renameItemName = ""

    private var isExpanded: Bool {
        expandedItems.contains(item.url)
    }

    private var isSelected: Bool {
        selectedFile == item.url
    }

    var body: some View {
                VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                // Indentation
                ForEach(0..<level, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 16)
                }

                // Disclosure triangle for directories
                if item.isDirectory {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 12, height: 12)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 12, height: 12)
                }

                if(!item.isDirectory) {
                    // File icon
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                }

                // File name
                Text(item.name)
                    .font(.system(size: 14))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(isSelected ? Color.accentColor.opacity(0.3) : Color.clear)
            .cornerRadius(4)
            .contentShape(Rectangle()) // Make entire HStack area clickable
            .onTapGesture {
                if item.isDirectory {
                    toggleExpansion()
                } else {
                    selectedFile = item.url
                }
            }
            .contextMenu {
                if item.isDirectory {
                    Button("New File") {
                        newItemName = ""
                        showingNewFileAlert = true
                    }

                    Button("New Folder") {
                        newItemName = ""
                        showingNewFolderAlert = true
                    }

                    Divider()
                }

                Button("Rename") {
                    renameItemName = item.name
                    showingRenameAlert = true
                }
            }

            // Children (if expanded)
            if isExpanded, let children = item.children {
                ForEach(children, id: \.id) { child in
                    FileItemView(
                        item: child,
                        level: level + 1,
                        expandedItems: $expandedItems,
                        selectedFile: $selectedFile,
                        onRefreshNeeded: {
                            // Only refresh the current directory's children, not the whole tree
                            if item.isDirectory && item.children != nil {
                                item.loadChildren()
                            }
                        }
                    )
                }
            }
        }
        .alert("New File", isPresented: $showingNewFileAlert) {
            TextField("File name", text: $newItemName)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                createNewFile()
            }
        } message: {
            Text("Enter the name for the new file")
        }
        .alert("New Folder", isPresented: $showingNewFolderAlert) {
            TextField("Folder name", text: $newItemName)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                createNewFolder()
            }
        } message: {
            Text("Enter the name for the new folder")
        }
        .alert("Rename", isPresented: $showingRenameAlert) {
            TextField("Name", text: $renameItemName)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                renameItem()
            }
        } message: {
            Text("Enter the new name")
        }
    }

    private func toggleExpansion() {
        if isExpanded {
            expandedItems.remove(item.url)
        } else {
            // Load children if not already loaded
            if item.children?.isEmpty == true {
                item.loadChildren()
            }
            expandedItems.insert(item.url)
        }
    }

    private func createNewFile() {
        guard !newItemName.isEmpty, item.isDirectory else { return }

        let newFileURL = item.url.appendingPathComponent(newItemName)

        do {
            // Create empty file
            FileManager.default.createFile(atPath: newFileURL.path, contents: Data(), attributes: nil)

            // Refresh the directory contents
            item.loadChildren()

            // Expand the directory if not already expanded
            if !isExpanded {
                expandedItems.insert(item.url)
            }
        } catch {
            print("Error creating file: \(error)")
        }
    }

    private func createNewFolder() {
        guard !newItemName.isEmpty, item.isDirectory else { return }

        let newFolderURL = item.url.appendingPathComponent(newItemName)

        do {
            try FileManager.default.createDirectory(at: newFolderURL, withIntermediateDirectories: false, attributes: nil)

            // Refresh the directory contents
            item.loadChildren()

            // Expand the directory if not already expanded
            if !isExpanded {
                expandedItems.insert(item.url)
            }
        } catch {
            print("Error creating folder: \(error)")
        }
    }

    private func renameItem() {
        guard !renameItemName.isEmpty, renameItemName != item.name else { return }

        let parentURL = item.url.deletingLastPathComponent()
        let newURL = parentURL.appendingPathComponent(renameItemName)

        do {
            try FileManager.default.moveItem(at: item.url, to: newURL)

            // Update the item's properties directly
            item.url = newURL
            item.name = renameItemName

            // If this was the selected file, update the selection
            if selectedFile != newURL {
                selectedFile = newURL
            }

            // Only trigger parent refresh to update the directory listing
            onRefreshNeeded()

        } catch {
            print("Error renaming item: \(error)")
        }
    }
}

#Preview {
    FileBrowserView(selectedFile: .constant(nil))
        .frame(width: 250, height: 400)
}
