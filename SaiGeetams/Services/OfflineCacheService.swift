import Foundation

final class OfflineCacheService {
    static let shared = OfflineCacheService()
    private let cacheDir: URL
    private let defaults = UserDefaults.standard
    private let prefix = "material__"

    private init() {
        cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("materials", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    func downloadMaterial(id: String, url: URL) async throws -> URL {
        let (data, _) = try await URLSession.shared.data(from: url)
        let filePath = cacheDir.appendingPathComponent(id)
        try data.write(to: filePath)
        defaults.set(filePath.path, forKey: prefix + id)
        return filePath
    }

    func cachedPath(for id: String) -> URL? {
        guard let path = defaults.string(forKey: prefix + id) else { return nil }
        let url = URL(fileURLWithPath: path)
        return FileManager.default.fileExists(atPath: path) ? url : nil
    }

    func deleteCached(id: String) {
        guard let path = defaults.string(forKey: prefix + id) else { return }
        try? FileManager.default.removeItem(atPath: path)
        defaults.removeObject(forKey: prefix + id)
    }
}
