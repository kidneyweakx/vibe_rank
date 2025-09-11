import Foundation

/// Simple local blocklist persisted in UserDefaults.
/// This prevents showing content from blocked users in the client feed.
final class UserBlocklist {
    static let shared = UserBlocklist()
    private init() {}

    private let defaultsKey = "blocked_user_ids"

    /// Returns a copy of the current blocked user id set
    var blockedUserIds: Set<String> {
        let ids = UserDefaults.standard.array(forKey: defaultsKey) as? [String] ?? []
        return Set(ids)
    }

    func isBlocked(_ userId: String) -> Bool {
        blockedUserIds.contains(userId)
    }

    func add(_ userId: String) {
        var set = blockedUserIds
        set.insert(userId)
        UserDefaults.standard.set(Array(set), forKey: defaultsKey)
    }

    func remove(_ userId: String) {
        var set = blockedUserIds
        set.remove(userId)
        UserDefaults.standard.set(Array(set), forKey: defaultsKey)
    }
}


