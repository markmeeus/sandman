//
//  ContentView.swift
//  sandman
//
//  Created by Mark Meeus on 02/09/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedFile: URL?
    @State private var rootFolderURL: URL?

    var body: some View {
        Group {
            if let rootURL = rootFolderURL {
                // Main interface with selected folder
                HSplitView {
                    // Left side: File browser
                    FileBrowserView(rootURL: rootURL, selectedFile: $selectedFile)
                        .frame(minWidth: 200, idealWidth: 250, maxWidth: 400)

                    // Right side: Document tabs and content
                    DocumentTabsView(selectedFile: $selectedFile)
                        .frame(minWidth: 400)
                }
                .frame(minWidth: 800, minHeight: 600)
                .background(Color(NSColor.windowBackgroundColor))
            } else {
                // Folder selection screen
                FolderSelectionView { selectedURL in
                    rootFolderURL = selectedURL
                }
                .frame(minWidth: 500, minHeight: 400)
            }
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 1000, height: 700)
}
