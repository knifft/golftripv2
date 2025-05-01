import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var router: NavigationRouter

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome Back")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color("PrimaryGreen"))

            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.top, -10)
            }

            Button("Login") {
                authViewModel.login(email: email, password: password)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)

            Button("Don't have an account? Register") {
                router.go(to: .register)
            }
            .font(.footnote)
            .foregroundColor(.blue)

            Spacer()
        }
        .padding()
        .navigationTitle("Login")
    }
}
