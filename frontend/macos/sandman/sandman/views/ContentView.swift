//
//  ContentView.swift
//  sandman
//
//  Created by Mark Meeus on 02/09/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedFile: URL?

    var body: some View {
        HSplitView {
            // Left side: File browser
            FileBrowserView(selectedFile: $selectedFile)
                .frame(minWidth: 200, idealWidth: 250, maxWidth: 400)

            // Right side: Document tabs and content
            DocumentTabsView(selectedFile: $selectedFile)
                .frame(minWidth: 400)
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    ContentView()
        .frame(width: 1000, height: 700)
}
