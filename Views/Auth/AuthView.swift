import SwiftUI

struct AuthView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if authViewModel.isLoggedIn {
                HomePageView()
            } else {
                LoginView()
            }
        }
        .environmentObject(authViewModel)
    }
}
