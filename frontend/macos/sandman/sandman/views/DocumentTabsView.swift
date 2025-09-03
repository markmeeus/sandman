//
//  DocumentTabsView.swift
//  sandman
//
//  Created by Mark Meeus on 02/09/2025.
//

import SwiftUI

struct DocumentTabsView: View {
    @State private var openTabs: [DocumentTab] = []
    @State private var selectedTabId: UUID?
    @Binding var selectedFile: URL?

    var selectedTab: DocumentTab? {
        openTabs.first { $0.id == selectedTabId }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            if !openTabs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(openTabs) { tab in
                            TabItemView(
                                tab: tab,
                                isSelected: tab.id == selectedTabId,
                                onSelect: { selectTab(tab) },
                                onClose: { closeTab(tab) }
                            )
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                }
                .frame(height: 32)
                .background(Color(NSColor.controlBackgroundColor))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(NSColor.separatorColor)),
                    alignment: .bottom
                )
            }

            // Document content area
            if let selectedTab = selectedTab {
                DocumentView(url: selectedTab.url)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("No Document Selected")
                        .font(.title2)
                        .foregroundColor(.secondary)

                    Text("Select a file from the browser to open it")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.textBackgroundColor))
            }
        }
        .onChange(of: selectedFile) { _, newFile in
            if let newFile = newFile {
                openFile(newFile)
            }
        }
    }

    private func openFile(_ url: URL) {
        // Check if file is already open
        if let existingTab = openTabs.first(where: { $0.url == url }) {
            selectedTabId = existingTab.id
            return
        }

        // Create new tab
        let newTab = DocumentTab(url: url)
        openTabs.append(newTab)
        selectedTabId = newTab.id
    }

    private func selectTab(_ tab: DocumentTab) {
        selectedTabId = tab.id
        selectedFile = tab.url
    }

    private func closeTab(_ tab: DocumentTab) {
        if let index = openTabs.firstIndex(where: { $0.id == tab.id }) {
            openTabs.remove(at: index)

            // If we closed the selected tab, select another one
            if selectedTabId == tab.id {
                if index < openTabs.count {
                    // Select the next tab
                    selectedTabId = openTabs[index].id
                    selectedFile = openTabs[index].url
                } else if !openTabs.isEmpty {
                    // Select the previous tab
                    selectedTabId = openTabs[openTabs.count - 1].id
                    selectedFile = openTabs[openTabs.count - 1].url
                } else {
                    // No tabs left
                    selectedTabId = nil
                    selectedFile = nil
                }
            }
        }
    }
}

struct TabItemView: View {
    let tab: DocumentTab
    let isSelected: Bool
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.text")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            Text(tab.title)
                .font(.system(size: 12))
                .lineLimit(1)
                .truncationMode(.middle)

            if tab.isModified {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
            }

            if isHovering || isSelected {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 14, height: 14)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Circle())
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color(NSColor.selectedContentBackgroundColor) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    DocumentTabsView(selectedFile: .constant(nil))
        .frame(width: 600, height: 400)
}
