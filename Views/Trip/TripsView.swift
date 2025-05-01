import SwiftUI

struct TripsView: View {
    var body: some View {
        GolftripScreen {
            VStack(alignment: .leading, spacing: 20) {
                Text("Your Trips")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
            }
        }
    }
}
