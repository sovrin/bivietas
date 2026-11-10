import Foundation

final class ConfigStore {
    let url: URL
    private var watcher: DispatchSourceFileSystemObject?

    init(url: URL = URL.applicationSupportDirectory.appending(path: "bivietas/config.json")) {
        self.url = url
    }

    /// nil if there is no config yet; throws if the file exists but can't be decoded.
    func load() throws -> Config? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try JSONDecoder().decode(Config.self, from: data)
    }

    func save(_ config: Config) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(config).write(to: url, options: .atomic)
    }

    /// Moves an undecodable config aside so saving defaults doesn't destroy it.
    func backUpUnreadable() {
        let backup = url.deletingLastPathComponent()
            .appending(path: "config.unreadable-\(Int(Date().timeIntervalSince1970)).json")
        try? FileManager.default.moveItem(at: url, to: backup)
    }

    /// Calls `onChange` on the main queue when the config directory changes
    /// (atomic writes replace the file, so the directory is watched, not the file).
    func watch(_ onChange: @escaping () -> Void) {
        let dir = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let fd = open(dir.path, O_EVTONLY)
        guard fd >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: .write, queue: .main)
        source.setEventHandler(handler: onChange)
        source.setCancelHandler { close(fd) }
        source.resume()
        watcher = source
    }
}
