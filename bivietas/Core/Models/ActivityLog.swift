import Foundation

/// Ring buffer of recent routing decisions, newest first.
struct ActivityLog {
    private(set) var entries: [LogEntry] = []
    var capacity = 100

    mutating func record(_ entry: LogEntry) {
        entries.insert(entry, at: 0)
        if entries.count > capacity { entries.removeLast(entries.count - capacity) }
    }
}
