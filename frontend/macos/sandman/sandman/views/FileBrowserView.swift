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

    init(selectedFile: Binding<URL?>) {
        self._selectedFile = selectedFile
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        var homeItem = FileItem(url: homeURL)
        homeItem.loadChildren()
        self._rootItem = State(initialValue: homeItem)
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
                        selectedFile: $selectedFile
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
                    Button(action: toggleExpansion) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 12, height: 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 12, height: 12)
                }

                // File/folder icon
                Image(systemName: item.isDirectory ? "folder.fill" : "doc.text.fill")
                    .font(.system(size: 12))
                    .foregroundColor(item.isDirectory ? .blue : .secondary)

                // File name
                Text(item.name)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(isSelected ? Color.accentColor.opacity(0.3) : Color.clear)
            .cornerRadius(4)
            .onTapGesture {
                if !item.isDirectory {
                    selectedFile = item.url
                }
            }

            // Children (if expanded)
            if isExpanded, let children = item.children {
                ForEach(children, id: \.id) { child in
                    FileItemView(
                        item: child,
                        level: level + 1,
                        expandedItems: $expandedItems,
                        selectedFile: $selectedFile
                    )
                }
            }
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
}

#Preview {
    FileBrowserView(selectedFile: .constant(nil))
        .frame(width: 250, height: 400)
}
