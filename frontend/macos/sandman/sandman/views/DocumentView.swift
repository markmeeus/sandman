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
