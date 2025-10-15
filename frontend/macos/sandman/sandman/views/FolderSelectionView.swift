//
//  FolderSelectionView.swift
//  sandman
//
//  Created by Mark Meeus on 02/09/2025.
//

import SwiftUI
import AppKit

struct FolderSelectionView: View {
    let onFolderSelected: (URL) -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)

                Text("Welcome to Sandman")
                    .font(.title)
                    .fontWeight(.semibold)

                Text("Please select a folder to get started")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Open Folder") {
                openFolderPicker()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(minWidth: 400, minHeight: 300)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.title = "Select Folder"
        panel.message = "Choose a folder to browse"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        panel.begin { response in
            if response == .OK, let url = panel.url {
                onFolderSelected(url)
            }
        }
    }
}

#Preview {
    FolderSelectionView { _ in
        print("Folder selected")
    }
    .frame(width: 500, height: 400)
}
