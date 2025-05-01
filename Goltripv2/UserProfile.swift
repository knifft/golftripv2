import Foundation

struct UserProfile: Identifiable, Equatable {
    var id: String { userId }
    let userId: String
    let displayName: String
    let profileImageURL: String?
}
