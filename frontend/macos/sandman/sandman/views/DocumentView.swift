//
//  DocumentView.swift
//  sandman
//
//  Created by Mark Meeus on 02/09/2025.
//

import SwiftUI

struct DocumentTab: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let title: String
    var isModified: Bool = false

    init(url: URL) {
        self.url = url
        self.title = url.lastPathComponent
    }
}

struct DocumentView: View {
    let url: URL
    @State private var content: String = ""
    @State private var isLoading: Bool = true
    @State private var error: String?

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)

                    Text("Error Loading File")
                        .font(.headline)

                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView([.horizontal, .vertical]) {
                    Text(content)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding()
                        .textSelection(.enabled)
                }
            }
        }
        .onAppear {
            loadContent()
        }
        .onChange(of: url) { _, _ in
            loadContent()
        }
    }

    private func loadContent() {
        isLoading = true
        error = nil

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let fileContent = try String(contentsOf: url, encoding: .utf8)

                DispatchQueue.main.async {
                    self.content = fileContent
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

#Preview {
    DocumentView(url: URL(fileURLWithPath: "/Users/Shared/test.txt"))
        .frame(width: 500, height: 400)
}
