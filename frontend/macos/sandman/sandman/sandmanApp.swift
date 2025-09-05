//
//  sandmanApp.swift
//  sandman
//
//  Created by Mark Meeus on 02/09/2025.
//

import SwiftUI
import SwiftData

@main
struct SandmanApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ZoomManager.shared)
        }
        .windowStyle(.automatic)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Zoom In") {
                    ZoomManager.shared.zoomIn()
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Zoom Out") {
                    ZoomManager.shared.zoomOut()
                }
                .keyboardShortcut("-", modifiers: .command)
            }
        }
    }
}

class ZoomManager: ObservableObject {
    static let shared = ZoomManager()
    @Published var zoomLevel: Double = 1.0

    private init() {}

    func zoomIn() {
        print("ZoomManager: Zooming in from \(zoomLevel)")
        zoomLevel = min(zoomLevel * 1.1, 3.0)
        print("ZoomManager: New zoom level: \(zoomLevel)")
    }

    func zoomOut() {
        print("ZoomManager: Zooming out from \(zoomLevel)")
        zoomLevel = max(zoomLevel / 1.1, 0.5)
        print("ZoomManager: New zoom level: \(zoomLevel)")
    }
}

