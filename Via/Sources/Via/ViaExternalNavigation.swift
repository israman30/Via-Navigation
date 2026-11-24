import Foundation

#if canImport(AppKit)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

/// Opens links outside the app using the platform's default browser or application handler.
@MainActor
public enum ViaExternalNavigation {
    /// Opens an HTTP, HTTPS, mail, or phone URL externally.
    @discardableResult
    public static func open(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(),
              ["http", "https", "mailto", "tel"].contains(scheme) else {
            return false
        }

        #if canImport(UIKit)
        guard UIApplication.shared.canOpenURL(url) else { return false }
        UIApplication.shared.open(url)
        return true
        #elseif canImport(AppKit)
        return NSWorkspace.shared.open(url)
        #else
        return false
        #endif
    }

    /// Opens a URL string externally. Bare domains are prefixed with `https://`.
    @discardableResult
    public static func open(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        if let url = URL(string: trimmed), url.scheme != nil {
            return open(url)
        }

        guard let url = URL(string: "https://\(trimmed)") else { return false }
        return open(url)
    }

    /// Explicit browser-navigation aliases.
    @discardableResult
    public static func openInBrowser(_ url: URL) -> Bool {
        open(url)
    }

    @discardableResult
    public static func openInBrowser(_ string: String) -> Bool {
        open(string)
    }
}
