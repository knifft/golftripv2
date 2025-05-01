import Foundation
import FirebaseFirestore

struct UserModel: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var uid: String
    var email: String
    var firstName: String
    var lastName: String
    var role: String
    var handicap: Double?
    var homeCourse: String?
    var profileImageURL: String? // Stored as a string from Firestore

    /// Computed property to convert string into a usable URL
    var profileImageURLAsURL: URL? {
        guard let urlString = profileImageURL else { return nil }
        return URL(string: urlString)
    }

    /// Full name for display purposes
    var displayName: String {
        "\(firstName) \(lastName)"
    }

    /// Convenience for displaying initials fallback
    var initials: String {
        let first = firstName.first.map(String.init) ?? ""
        let last = lastName.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }
}
