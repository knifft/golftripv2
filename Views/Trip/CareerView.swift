import SwiftUI

struct CareerView: View {
    var body: some View {
        GolftripScreen {
            VStack(alignment: .leading, spacing: 20) {
                Text("Career in Review")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
            }
        }
    }
}
