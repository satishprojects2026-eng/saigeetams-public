import Foundation
import UIKit

@MainActor
class AppUpdateService: ObservableObject {
    static let shared = AppUpdateService()

    @Published var updateRequired = false
    @Published var appStoreVersion: String = ""

    private let bundleId = Bundle.main.bundleIdentifier ?? ""
    private let currentVersion: String = {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }()

    private init() {}

    /// Call on every app launch. If a newer version exists on the App Store,
    /// immediately opens the App Store page and blocks the app.
    /// No dialog, no Later button, no user choice -- they must update.
    func checkForUpdate() async {
        guard let storeVersion = await fetchAppStoreVersion() else { return }
        appStoreVersion = storeVersion

        guard isNewer(storeVersion, than: currentVersion) else { return }

        // New version exists -- block app and open App Store
        updateRequired = true
        openAppStore()
    }

    /// Called when app comes back to foreground after user updates (or doesn't).
    /// Re-checks and keeps blocking if still outdated.
    func recheckOnForeground() async {
        guard updateRequired else { return }
        guard let storeVersion = await fetchAppStoreVersion() else { return }
        if isNewer(storeVersion, than: currentVersion) {
            openAppStore()
        } else {
            updateRequired = false
        }
    }

    func openAppStore() {
        guard let url = URL(string: "https://apps.apple.com/app/id\(AppSettings.appStoreId)") else { return }
        UIApplication.shared.open(url)
    }

    private func fetchAppStoreVersion() async -> String? {
        guard !bundleId.isEmpty else { return nil }
        let urlString = "https://itunes.apple.com/lookup?bundleId=\(bundleId)&country=us"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(ITunesLookupResponse.self, from: data)
            return response.results.first?.version
        } catch {
            return nil
        }
    }

    private func isNewer(_ a: String, than b: String) -> Bool {
        let aParts = a.split(separator: ".").compactMap { Int($0) }
        let bParts = b.split(separator: ".").compactMap { Int($0) }
        let count = max(aParts.count, bParts.count)
        for i in 0..<count {
            let av = i < aParts.count ? aParts[i] : 0
            let bv = i < bParts.count ? bParts[i] : 0
            if av > bv { return true }
            if av < bv { return false }
        }
        return false
    }
}

private struct ITunesLookupResponse: Decodable {
    let resultCount: Int
    let results: [ITunesApp]
}

private struct ITunesApp: Decodable {
    let version: String
}
