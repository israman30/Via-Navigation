import Foundation

public struct ViaURLNavigation<Route> {
    public enum Mode: Sendable {
        /// Replace the entire stack with `routes`.
        case setPath
        /// Append `routes` to the existing stack.
        case push
        /// Replace the stack with a single route.
        case replace
    }

    public var routes: [Route]
    public var mode: Mode

    public init(_ routes: [Route], mode: Mode = .setPath) {
        self.routes = routes
        self.mode = mode
    }

    public static func setPath(_ routes: [Route]) -> Self { Self(routes, mode: .setPath) }
    public static func push(_ routes: [Route]) -> Self { Self(routes, mode: .push) }
    public static func replace(with route: Route) -> Self { Self([route], mode: .replace) }
}

public struct ViaURLRequest: Sendable {
    public let url: URL
    public let pathParameters: [String: String]
    public let queryParameters: [String: String]
    public let fragment: String?

    public var parameters: [String: String] {
        var merged = queryParameters
        for (k, v) in pathParameters { merged[k] = v }
        return merged
    }

    public init(
        url: URL,
        pathParameters: [String: String],
        queryParameters: [String: String],
        fragment: String?
    ) {
        self.url = url
        self.pathParameters = pathParameters
        self.queryParameters = queryParameters
        self.fragment = fragment
    }
}

public struct ViaURLMatch<Route> {
    public let request: ViaURLRequest
    public let navigation: ViaURLNavigation<Route>
}

public final class ViaURLRouter<Route> {
    public typealias Handler = @Sendable (ViaURLRequest) -> ViaURLNavigation<Route>?

    public init() {}

    /// Register a URL pattern and produce navigation for matches.
    ///
    /// Pattern format:
    /// - `myapp://profile/settings`
    /// - `myapp:///profile/:section`
    /// - `https://example.com/profile/:id`
    /// - `/profile/:id` (path-only; matches any scheme/host)
    ///
    /// Rules:
    /// - Path parameters are written as `:name`
    /// - `*` matches the remainder of the path (no parameters)
    /// - For non-HTTP schemes, `myapp://profile/settings` treats `profile` as the first path segment.
    public func register(_ pattern: String, handler: @escaping Handler) {
        entries.append(Entry(pattern: ViaURLPattern(pattern), handler: handler))
    }

    /// Convenience: register a pattern that returns a stack to set as the path.
    public func register(_ pattern: String, routes: @escaping @Sendable (ViaURLRequest) -> [Route]?) {
        register(pattern) { req in
            guard let r = routes(req) else { return nil }
            return ViaURLNavigation(r, mode: .setPath)
        }
    }

    public func resolve(_ url: URL) -> ViaURLMatch<Route>? {
        let info = ViaURLInfo(url: url)
        for entry in entries {
            guard let pathParams = entry.pattern.match(info: info) else { continue }
            let req = ViaURLRequest(
                url: url,
                pathParameters: pathParams,
                queryParameters: info.queryParameters,
                fragment: info.fragment
            )
            guard let nav = entry.handler(req) else { continue }
            return ViaURLMatch(request: req, navigation: nav)
        }
        return nil
    }

    private struct Entry {
        let pattern: ViaURLPattern
        let handler: Handler
    }

    private var entries: [Entry] = []
}

// MARK: - Tab routing

public struct ViaTabURLNavigation<Tab, Route> {
    public enum Mode: Sendable {
        case setPath
        case push
        case replace
    }

    /// If `nil`, the navigator’s `selectedTab` is used.
    public var tab: Tab?
    public var routes: [Route]
    public var mode: Mode
    /// If a `tab` is provided, whether to switch to it before applying navigation.
    public var selectTab: Bool

    public init(tab: Tab? = nil, routes: [Route], mode: Mode = .setPath, selectTab: Bool = true) {
        self.tab = tab
        self.routes = routes
        self.mode = mode
        self.selectTab = selectTab
    }

    public static func setPath(tab: Tab? = nil, _ routes: [Route], selectTab: Bool = true) -> Self {
        Self(tab: tab, routes: routes, mode: .setPath, selectTab: selectTab)
    }

    public static func push(tab: Tab? = nil, _ routes: [Route], selectTab: Bool = true) -> Self {
        Self(tab: tab, routes: routes, mode: .push, selectTab: selectTab)
    }

    public static func replace(tab: Tab? = nil, with route: Route, selectTab: Bool = true) -> Self {
        Self(tab: tab, routes: [route], mode: .replace, selectTab: selectTab)
    }
}

public struct ViaTabURLMatch<Tab, Route> {
    public let request: ViaURLRequest
    public let navigation: ViaTabURLNavigation<Tab, Route>
}

public final class ViaTabURLRouter<Tab, Route> {
    public typealias Handler = @Sendable (ViaURLRequest) -> ViaTabURLNavigation<Tab, Route>?

    public init() {}

    public func register(_ pattern: String, handler: @escaping Handler) {
        entries.append(Entry(pattern: ViaURLPattern(pattern), handler: handler))
    }

    public func resolve(_ url: URL) -> ViaTabURLMatch<Tab, Route>? {
        let info = ViaURLInfo(url: url)
        for entry in entries {
            guard let pathParams = entry.pattern.match(info: info) else { continue }
            let req = ViaURLRequest(
                url: url,
                pathParameters: pathParams,
                queryParameters: info.queryParameters,
                fragment: info.fragment
            )
            guard let nav = entry.handler(req) else { continue }
            return ViaTabURLMatch(request: req, navigation: nav)
        }
        return nil
    }

    private struct Entry {
        let pattern: ViaURLPattern
        let handler: Handler
    }

    private var entries: [Entry] = []
}

// MARK: - URL parsing / pattern matching (internal)

private struct ViaURLInfo {
    let scheme: String?
    let host: String?
    let segments: [String]
    let queryParameters: [String: String]
    let fragment: String?

    init(url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        scheme = components?.scheme?.lowercased()
        fragment = components?.fragment

        let rawHost = components?.host
        let isHTTP = (scheme == "http" || scheme == "https")
        host = isHTTP ? rawHost?.lowercased() : nil

        let pathSegments = ViaURLInfo.splitPath(components?.path ?? url.path)
        if isHTTP {
            segments = pathSegments
        } else if let rawHost, !rawHost.isEmpty {
            segments = [rawHost] + pathSegments
        } else {
            segments = pathSegments
        }

        var q: [String: String] = [:]
        for item in (components?.queryItems ?? []) {
            guard let value = item.value else { continue }
            q[item.name] = value
        }
        queryParameters = q
    }

    private static func splitPath(_ path: String) -> [String] {
        path
            .split(separator: "/", omittingEmptySubsequences: true)
            .map { String($0) }
    }
}

private struct ViaURLPattern {
    private let scheme: String?
    private let host: String?
    private let segments: [Segment]

    init(_ pattern: String) {
        let trimmed = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("/") {
            scheme = nil
            host = nil
            segments = ViaURLPattern.parseSegments(fromPathLike: trimmed)
            return
        }

        if let url = URL(string: trimmed), let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            let s = comps.scheme?.lowercased()
            let isHTTP = (s == "http" || s == "https")
            scheme = s
            host = isHTTP ? comps.host?.lowercased() : nil

            let pathSegments = ViaURLPattern.parseSegments(fromPathLike: comps.path)
            if isHTTP {
                segments = pathSegments
            } else if let h = comps.host, !h.isEmpty {
                segments = [ViaURLPattern.literal(h)] + pathSegments
            } else {
                segments = pathSegments
            }
            return
        }

        scheme = nil
        host = nil
        segments = ViaURLPattern.parseSegments(fromPathLike: trimmed)
    }

    func match(info: ViaURLInfo) -> [String: String]? {
        if let scheme, scheme != info.scheme { return nil }
        if let host, host != info.host { return nil }

        var params: [String: String] = [:]
        var i = 0
        var j = 0

        while i < segments.count, j < info.segments.count {
            switch segments[i] {
            case .wildcard:
                return params
            case .literal(let lit):
                guard lit == info.segments[j] else { return nil }
            case .parameter(let name):
                params[name] = info.segments[j]
            }
            i += 1
            j += 1
        }

        if i < segments.count {
            if case .wildcard = segments[i], i == segments.count - 1 {
                return params
            }
            return nil
        }

        return (j == info.segments.count) ? params : nil
    }

    private static func parseSegments(fromPathLike path: String) -> [Segment] {
        let raw = path
            .split(separator: "/", omittingEmptySubsequences: true)
            .map { String($0) }
        return raw.map { seg in
            if seg == "*" { return .wildcard }
            if seg.hasPrefix(":"), seg.count > 1 { return .parameter(String(seg.dropFirst())) }
            return .literal(seg)
        }
    }

    private static func literal(_ string: String) -> Segment {
        .literal(string)
    }

    private enum Segment: Equatable, Sendable {
        case literal(String)
        case parameter(String)
        case wildcard
    }
}
