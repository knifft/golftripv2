import SwiftUI

struct ScorecardUploadView: View {
    @StateObject private var viewModel = ScorecardUploadViewModel()
    @State private var isCameraPresented = false
    @State private var selectedSide: ScorecardSide? = nil

    var body: some View {
        VStack(spacing: 20) {
            Text("Upload Scorecard Images")
                .font(.title)
                .bold()

            imageSlot(title: "Front 9", image: viewModel.frontNineImage, side: .front)
            imageSlot(title: "Back 9", image: viewModel.backNineImage, side: .back)

            if viewModel.isReadyToAnalyze {
                Button(action: {
                    Task { await viewModel.processBothImages() }
                }) {
                    HStack {
                        if viewModel.isSendingToGPT {
                            ProgressView()
                        }
                        Text("Analyze Full Scorecard")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.top)
            }

            if let debug = viewModel.debugMessage {
                Text(debug)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .padding(.horizontal)
            }

            if let scorecard = viewModel.editableScorecard,
               !scorecard.player_scores.isEmpty {
                ScorecardReviewView(scorecard: $viewModel.editableScorecard, playerIndex: 0)
                Button("Save to Firestore") {
                    viewModel.saveToFirestore()
                }
                .padding()
            }
        }
        .padding()
        .sheet(isPresented: $isCameraPresented) {
            ImagePicker(sourceType: .camera) { image in
                if let image = image {
                    viewModel.setImage(image, for: selectedSide)
                }
                isCameraPresented = false
            }
        }
    }

    private func imageSlot(title: String, image: UIImage?, side: ScorecardSide) -> some View {
        Button {
            selectedSide = side
            isCameraPresented = true
        } label: {
            VStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary, style: StrokeStyle(lineWidth: 1, dash: [5]))
                        .frame(height: 150)
                        .overlay(Text(title).foregroundColor(.secondary))
                }
            }
        }
    }
}

enum ScorecardSide {
    case front, back
}
