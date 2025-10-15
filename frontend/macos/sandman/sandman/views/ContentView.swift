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
    @EnvironmentObject var zoomManager: ZoomManager
    @EnvironmentObject var phoenixManager: PhoenixManager

    var body: some View {
        Group {
            if let rootURL = rootFolderURL {
                // Main interface with selected folder
                HSplitView {
                    // Left side: File browser
                    FileBrowserView(rootURL: rootURL, selectedFile: $selectedFile, zoomLevel: zoomManager.zoomLevel)
                        .frame(minWidth: 200, idealWidth: 250, maxWidth: 400)

                    // Right side: Document tabs and content
                    DocumentTabsView(selectedFile: $selectedFile, zoomLevel: zoomManager.zoomLevel)
                        .frame(minWidth: 400)
                }
                .frame(minWidth: 800, minHeight: 600)
                .background(Color(red: 0.2, green: 0.2, blue: 0.2)) // neutral-800 equivalent
                .onChange(of: zoomManager.zoomLevel) { _, newValue in
                    print("ContentView: Zoom level changed to \(newValue)")
                }
                .overlay(alignment: .topTrailing) {
                    // Phoenix status indicator
                    Circle()
                        .fill(phoenixManager.isRunning ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                        .padding(.top, 8)
                        .padding(.trailing, 8)
                }
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
        .environmentObject(ZoomManager.shared)
        .environmentObject(PhoenixManager())
        .frame(width: 1000, height: 700)
}
