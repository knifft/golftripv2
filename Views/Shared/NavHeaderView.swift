import SwiftUI

// MARK: - Top Navigation Bar

struct TopNavigationBar: View {
    var body: some View {
        GeometryReader { geo in
            let topInset = geo.safeAreaInsets.top

            HStack {
                Image(systemName: "figure.golf")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundColor(.primary)

                Text("Let’s hit the fairway")
                    .foregroundColor(.primary)
                    .font(.headline)

                Spacer()

                ProfileAvatarButton()
            }
            .padding(.top, topInset + 8)
            .padding(.horizontal)
            .padding(.bottom, 12)
            .background(
                Color.black.opacity(0.6)
                    .blur(radius: 10)
            )
            .cornerRadius(10)
            .ignoresSafeArea(edges: .top)
        }
        .frame(height: 60)
    }
}

// MARK: - Profile Avatar Button

struct ProfileAvatarButton: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var router: NavigationRouter

    var body: some View {
        Menu {
            Button("Profile") {
                router.go(to: .profile)
            }
            Button("Sign Out") {
                authViewModel.signOut()
            }
        } label: {
            AvatarView(
                name: authViewModel.currentUser?.displayName ?? "User",
                imageURL: authViewModel.currentUser?.profileImageURL,
                size: 28
            )
        }
    }
}
