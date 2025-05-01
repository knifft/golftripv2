import Foundation

struct TeeOption: Codable {
    var color: String
    var course_rating: Double?
    var slope_rating: Int?
}

struct ScorecardData: Codable {
    var course_name: String
    var course_rating: Double?
    var slope_rating: Int?
    var tee_color: String?
    var tee_options: [TeeOption]?
    var player_scores: [PlayerScore]
}

struct PlayerScore: Identifiable, Codable {
    var id = UUID()
    var player_name: String
    var hole_scores: [HoleScore]
}

struct HoleScore: Identifiable, Codable {
    var id: Int { holeNumber }
    var holeNumber: Int
    var par: Int
    var score: Int
}
