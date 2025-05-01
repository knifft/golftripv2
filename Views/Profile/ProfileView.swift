import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isEditingProfile = false

    var body: some View {
        VStack(spacing: 20) {
            if let user = authViewModel.currentUser {
                VStack(spacing: 16) {
                    AvatarView(name: user.displayName, imageURL: user.profileImageURL, size: 100)

                    Text("Welcome, \(user.firstName)")
                        .font(.largeTitle)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("📧 Email: \(user.email)")
                        Text("🧑‍💼 Role: \(user.role)")
                        Text("⛳️ Handicap: \(user.handicap.map { String($0) } ?? "—")")
                        Text("🏠 Home Course: \(user.homeCourse ?? "—")")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            } else {
                ProgressView("Loading profile...")
            }

            Spacer()
        }
        .navigationTitle("My Profile")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    isEditingProfile = true
                }
            }
        }
        .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $isEditingProfile) {
            if let user = authViewModel.currentUser {
                EditProfileView(user: user)
                    .environmentObject(authViewModel)
            }
        }
    }
}
