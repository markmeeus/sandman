//
//  DocumentTabsView.swift
//  sandman
//
//  Created by Mark Meeus on 02/09/2025.
//

import SwiftUI
import WebKit

struct DocumentTabsView: View {
    @State private var openTabs: [DocumentTab] = []
    @State private var selectedTabId: UUID?
    @State private var webViews: [UUID: WebViewContainer] = [:]
    @Binding var selectedFile: URL?
    let zoomLevel: Double

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
            if selectedTab != nil {
                ZStack {
                    // Show all webviews but only make the selected one visible
                    ForEach(openTabs, id: \.id) { tab in
                        if let webViewContainer = webViews[tab.id] {
                            WebViewWrapper(
                                container: webViewContainer,
                                zoomLevel: zoomLevel
                            )
                            .opacity(tab.id == selectedTabId ? 1 : 0)
                        }
                    }
                }
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
                .background(Color(red: 0.2, green: 0.2, blue: 0.2)) // neutral-800 equivalent
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

        // Create WebView container for this tab
        let webViewContainer = WebViewContainer(url: url)
        webViews[newTab.id] = webViewContainer
    }

    private func selectTab(_ tab: DocumentTab) {
        selectedTabId = tab.id
        selectedFile = tab.url
    }

    private func closeTab(_ tab: DocumentTab) {
        if let index = openTabs.firstIndex(where: { $0.id == tab.id }) {
            openTabs.remove(at: index)

            // Clean up the WebView container
            webViews.removeValue(forKey: tab.id)

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

class NavigationDelegate : NSObject, WKNavigationDelegate {
    var loadedOnce = false
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        if !loadedOnce {
            loadedOnce = true
            return .allow
        } else {
            if let url = navigationAction.request.url {
                // Open in default browser instead of WebView
                NSWorkspace.shared.open(url)
                return .cancel
            }
            return .cancel
        }
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("didStartProvisionalNavigation")
    }
}

// WebView container to maintain state
class WebViewContainer: ObservableObject {
    let webView: WKWebView
    let url: URL
    let navigationDelegate: NavigationDelegate
    
    init(url: URL) {
        self.url = url
        self.webView = WKWebView()
        self.navigationDelegate = NavigationDelegate()
        self.webView.navigationDelegate = self.navigationDelegate
        // Build the localhost URL with file parameter
        var components = URLComponents()
        components.scheme = "http"
        components.host = "localhost"
        components.port = 7000
        components.queryItems = [URLQueryItem(name: "file", value: url.path)]

        let webURL = components.url ?? URL(string: "http://localhost:7000")!

        // Load the URL once
        self.webView.load(URLRequest(url: webURL))
    }
}

// SwiftUI wrapper for persistent WebView
struct WebViewWrapper: NSViewRepresentable {
    let container: WebViewContainer
    let zoomLevel: Double
    
    func makeNSView(context: Context) -> WKWebView {
        return container.webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // Only update zoom level, don't reload
        nsView.pageZoom = zoomLevel
    }
}

#Preview {
    DocumentTabsView(selectedFile: .constant(nil), zoomLevel: 1.0)
        .frame(width: 600, height: 400)
}
