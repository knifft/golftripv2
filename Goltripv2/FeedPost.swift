import Foundation
import FirebaseFirestore

struct FeedComment: Codable, Identifiable {
    var id: String { UUID().uuidString }
    let userId: String
    let userDisplayName: String
    let userProfileImageURL: String?
    let comment: String
    let timestamp: Timestamp
}

struct FeedPost: Codable, Identifiable {
    @DocumentID var id: String?
    let userId: String
    let authorDisplayName: String
    let authorProfileImageURL: String?
    let content: String
    let timestamp: Timestamp
    let likes: [String]
    let comments: [FeedComment]
    // ✅ New
    let mediaURLs: [String]?
    let mediaTypes: [String]? // "image" or "video"
}



