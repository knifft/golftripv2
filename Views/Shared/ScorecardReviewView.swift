import SwiftUI
import Foundation

struct ScorecardReviewView: View {
    @Binding var scorecard: ScorecardData?
    var playerIndex: Int
    var rawText: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if scorecard != nil, playerIndex < scorecard!.player_scores.count {

                Text("Review & Edit Scorecard")
                    .font(.headline)

                if let rawText = rawText, !rawText.isEmpty {
                    GroupBox(label: Text("Raw OCR Text Used")) {
                        ScrollView {
                            Text(rawText)
                                .font(.caption)
                                .padding(4)
                        }
                        .frame(maxHeight: 100)
                    }
                }

                TextField("Course Name", text: Binding(
                    get: { scorecard!.course_name },
                    set: { scorecard!.course_name = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField("Player Name", text: Binding(
                    get: { scorecard!.player_scores[playerIndex].player_name },
                    set: { scorecard!.player_scores[playerIndex].player_name = $0 }
                ))
                .textFieldStyle(RoundedBorderTextFieldStyle())

                Divider().padding(.vertical, 8)

                ForEach(scorecard!.player_scores[playerIndex].hole_scores.indices, id: \ .self) { index in
                    let hole = scorecard!.player_scores[playerIndex].hole_scores[index]
                    HStack {
                        Text("Hole \(hole.holeNumber)")
                        Spacer()
                        Stepper(value: Binding(
                            get: { scorecard!.player_scores[playerIndex].hole_scores[index].score },
                            set: { scorecard!.player_scores[playerIndex].hole_scores[index].score = $0 }
                        ), in: 1...12) {
                            Text("\(scorecard!.player_scores[playerIndex].hole_scores[index].score)")
                        }
                    }
                }
            }
        }
        .padding()
    }
}
