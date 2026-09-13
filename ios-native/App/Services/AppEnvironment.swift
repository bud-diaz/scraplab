import Foundation

/// Single source of truth for the backend base URL every store/loader talks to.
enum AppEnvironment {
    static let apiBaseURL = URL(string: "https://scraplab-inky.vercel.app")!
}
