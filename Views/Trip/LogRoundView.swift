import SwiftUI

struct LogRoundView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        GolftripScreen {
            Text("Log Round Screen (Coming Soon)")
                .padding()
        }
        .navigationTitle("Let’s hit the fairway, \(authViewModel.currentUser?.firstName ?? "golfer") ⛳️")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Image(systemName: "figure.golf")
                    .resizable()
                    .frame(width: 22, height: 22)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                ProfileAvatarButton()
            }
        }
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
