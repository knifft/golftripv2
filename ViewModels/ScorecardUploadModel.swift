import Foundation
import SwiftUI
import FirebaseFirestore
import Vision

@MainActor
class ScorecardUploadViewModel: ObservableObject {


    @Published var frontNineImage: UIImage?
    @Published var backNineImage: UIImage?
    @Published var editableScorecard: ScorecardData?
    @Published var isSendingToGPT = false
    @Published var debugMessage: String? = nil
    @Published var rawOCRText: String? = nil

    private var parsedFront: ScorecardData?
    private var parsedBack: ScorecardData?

    var isReadyToAnalyze: Bool {
        frontNineImage != nil && backNineImage != nil
    }

    func setImage(_ image: UIImage, for side: ScorecardSide?) {
        switch side {
        case .front: frontNineImage = image
        case .back: backNineImage = image
        case .none: break
        }
    }

    func recognizeText(from image: UIImage) async -> String? {
        guard let cgImage = image.cgImage else { return nil }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["en-US"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
            let text = request.results?.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
            return text
        } catch {
            debugMessage = "OCR failed: \(error.localizedDescription)"
            return nil
        }

    
    }

    func generateHoleScores(from scores: [Int]) -> [HoleScore] {
        let filledScores = scores + Array(repeating: 4, count: max(0, 18 - scores.count))
        return zip(1...18, filledScores).map { HoleScore(holeNumber: $0.0, par: 4, score: $0.1) }
    }

    func processBothImages() async {
        guard let front = frontNineImage, let back = backNineImage else { return }

        isSendingToGPT = true
        debugMessage = nil
        async let frontText = recognizeText(from: front)
        async let backText = recognizeText(from: back)

        let combinedText = (await frontText ?? "") + "\n" + (await backText ?? "")
        rawOCRText = combinedText
        print("""
📝 OCR TEXT:
\(combinedText)
""")
        parsedFront = try? await sendToGPT(using: combinedText, ocrText: combinedText)

        isSendingToGPT = false

        if let scorecard = parsedFront {
            editableScorecard = scorecard
        }
    }

    

    }




// MARK: - End of ViewModel class

extension ScorecardUploadViewModel {

    func detectPlayerName(from observations: [VNRecognizedTextObservation]) -> String? {
        // Group text by horizontal rows
        let groupedRows = Dictionary(grouping: observations) { obs in
            round(obs.boundingBox.midY * 100) / 100  // Normalize Y position
        }

        // Score each row for a handwritten-style name followed by numeric scores
        for (_, row) in groupedRows.sorted(by: { $0.key < $1.key }) {
            let sorted = row.sorted(by: { $0.boundingBox.minX < $1.boundingBox.minX })
            guard let firstText = sorted.first?.topCandidates(1).first?.string else { continue }

            // Heuristic: first word is long, alphabetic, likely a name
            if firstText.range(of: "^[A-Z][a-zA-Z]{2,}$", options: .regularExpression) != nil {
                let rest = sorted.dropFirst().compactMap { $0.topCandidates(1).first?.string }
                let numericCount = rest.filter { Int($0) != nil }.count

                // If the row has 5+ numbers after a potential name, it’s likely the score row
                if numericCount >= 5 {
                    return firstText
                }
            }
        }

        return nil
    }

}

struct ScorecardMetadata: Codable {
    var player_name: String?
    var course_name: String?
    var tee_color: TeeColorUnion?
}

enum TeeColorUnion: Codable {
    case string(String)
    case array([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let array = try? container.decode([String].self) {
            self = .array(array)
        } else {
            throw DecodingError.typeMismatch(
                TeeColorUnion.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Tee color wasn't a string or array")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .array(let array): try container.encode(array)
        }
    }
}

extension ScorecardUploadViewModel {

    func extractHandwrittenScores(from observations: [VNRecognizedTextObservation]) -> [Int] {
    // Group by horizontal lines
    let groupedRows = Dictionary(grouping: observations) { round($0.boundingBox.midY * 100) / 100 }

    // Score each row by how many 1-2 digit numbers it contains
    let bestRow: [Int] = groupedRows
        .mapValues { row in
            row.compactMap { obs in
                guard let str = obs.topCandidates(1).first?.string.trimmingCharacters(in: .whitespaces),
                      let num = Int(str), (1...12).contains(num) else { return nil }
                return num
            }
        }
        .filter { $0.value.count >= 5 } // row must look like scores
        .max(by: { $0.value.count < $1.value.count })?.value ?? []

    return Array(bestRow.prefix(18))
}

    func sendToGPT(using text: String, playerName: String? = nil, ocrText: String) async throws -> ScorecardData? {
        guard let apiKey = loadOpenAIKey() else {
            debugMessage = "Missing OpenAI API Key"
            return nil
        }

        let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let userContent = """
Here is the OCR text from a scorecard:

\(text)
"""

        let body: [String: Any] = [
            "model": "gpt-4-turbo",
            "messages": [
                [
                    "role": "system",
                    "content": """
You are a golf scorecard parser. You will receive raw OCR text from a scorecard image. Extract ONLY the following fields:

1. player_name — if clearly legible
2. course_name — if printed or readable
3. tee_color — if clearly marked

Do NOT include player scores, hole numbers, or par information. Return structured JSON with just these fields.
"""
                ],
                [
                    "role": "user",
                    "content": userContent
                ]
            ],
            "max_tokens": 1500
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        if let raw = String(data: data, encoding: .utf8) {
            print("GPT raw response: \(raw)")
        }

        guard let decoded = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = decoded["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            debugMessage = "Unexpected GPT response structure"
            return nil
        }

        let rawJSONString: String = {
    let extracted = content.components(separatedBy: "```")
        .first(where: { $0.contains("{") && $0.contains("course_name") })?
        .replacingOccurrences(of: "json", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    return extracted ?? content
}()

        let jsonString = rawJSONString
            .replacingOccurrences(of: "\"slope\": \"N/A\"", with: "\"slope\": null")
            .replacingOccurrences(of: "\"slope\": \"Not indicated\"", with: "\"slope\": null")
            .replacingOccurrences(of: "\"slope\": \"\"", with: "\"slope\": null")
            .replacingOccurrences(of: "\"slope\": \"Not Available\"", with: "\"slope\": null")
            .replacingOccurrences(of: "\"slope\": \"Not specified\"", with: "\"slope\": null")

        guard let jsonData = jsonString.data(using: .utf8) else {
            debugMessage = "Failed to convert cleaned JSON string to Data"
            return nil
        }

        do {
            let logMessage = """
🧪 JSON before decoding:
\(jsonString)
"""
            print(logMessage)

            let metadata = try JSONDecoder().decode(ScorecardMetadata.self, from: jsonData)

            var teeColor: String? = nil
            var teeOptions: [TeeOption]? = nil

            switch metadata.tee_color {
            case .string(let single):
                teeColor = single
            case .array(let multiple):
                teeOptions = multiple.map { TeeOption(color: $0, course_rating: nil, slope_rating: nil) }
            case .none:
                break
            }

            let cgImage = frontNineImage?.cgImage
let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.recognitionLanguages = ["en-US"]
request.usesLanguageCorrection = true

var observations: [VNRecognizedTextObservation] = []
if let cgImage = cgImage {
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try? handler.perform([request])
    observations = (request.results as? [VNRecognizedTextObservation]) ?? []
}

            let scores = extractHandwrittenScores(from: observations)
            let holes = generateHoleScores(from: scores)

            let detectedName = detectPlayerName(from: observations)
            let finalPlayerName = (metadata.player_name?.lowercased() != "unknown" && metadata.player_name != nil)
                ? metadata.player_name!
                : (detectedName ?? "Unknown")

            let player = PlayerScore(player_name: finalPlayerName, hole_scores: holes)
            return ScorecardData(
                course_name: metadata.course_name ?? "",
                course_rating: nil,
                slope_rating: nil,
                tee_color: teeColor,
                tee_options: teeOptions,
                player_scores: [player]
            )
        } catch {
            debugMessage = "❌ Decoding error: \(error.localizedDescription)\n\nRaw JSON for inspection:\n\(jsonString)"
            print("\u{274C} JSON decoding failed:\n\(jsonString)")
            return nil
        }
    }

    func saveToFirestore() {
        guard let scorecard = editableScorecard else { return }
        do {
            let data = try JSONEncoder().encode(scorecard)
            let json = try JSONSerialization.jsonObject(with: data)
            Firestore.firestore().collection("scorecards").addDocument(data: json as! [String: Any])
        } catch {
            print("Failed to save to Firestore: \(error.localizedDescription)")
        }
    }

    private func loadOpenAIKey() -> String? {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return nil
        }
        return dict["OpenAI_API_Key"] as? String
    }
}
