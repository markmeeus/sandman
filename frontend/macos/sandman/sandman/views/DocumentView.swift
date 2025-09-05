//
//  DocumentView.swift
//  sandman
//
//  Created by Mark Meeus on 02/09/2025.
//

import SwiftUI
import WebKit

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

struct WebView: NSViewRepresentable {
    let url: URL
    let zoomLevel: Double

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if(nsView.url != url) {
            nsView.load(URLRequest(url: url))
        }
        // Apply zoom level to webview
        nsView.pageZoom = zoomLevel
    }
}

struct DocumentView: View {
    let url: URL
    let zoomLevel: Double

    private var webURL: URL {
        var components = URLComponents()
        components.scheme = "http"
        components.host = "localhost"
        components.port = 7000
        components.queryItems = [URLQueryItem(name: "file", value: url.path)]

        return components.url ?? URL(string: "http://localhost:7000")!
    }

    var body: some View {
        WebView(url: webURL, zoomLevel: zoomLevel)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    DocumentView(url: URL(fileURLWithPath: "/Users/Shared/test.txt"), zoomLevel: 1.0)
        .frame(width: 500, height: 400)
}
