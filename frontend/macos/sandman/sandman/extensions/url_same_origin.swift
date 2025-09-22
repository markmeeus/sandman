import Foundation
extension URL {
    func hasSameOrigin(as other: URL) -> Bool {
        guard let host = self.host,
              let otherHost = other.host else {
            return false
        }
        
        // Default ports: 80 for http, 443 for https
        func effectivePort(for url: URL) -> Int {
            if let port = url.port {
                return port
            }
            switch url.scheme?.lowercased() {
            case "http": return 80
            case "https": return 443
            default: return -1 // Unknown
            }
        }
        
        return self.scheme?.lowercased() == other.scheme?.lowercased()
            && host.caseInsensitiveCompare(otherHost) == .orderedSame
            && effectivePort(for: self) == effectivePort(for: other)
    }
}
