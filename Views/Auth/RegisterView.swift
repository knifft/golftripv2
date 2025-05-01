import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var router: NavigationRouter

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section(header: Text("Name")) {
                TextField("First Name", text: $firstName)
                    .textContentType(.givenName)
                    .autocapitalization(.words)

                TextField("Last Name", text: $lastName)
                    .textContentType(.familyName)
                    .autocapitalization(.words)
            }

            Section(header: Text("Account Info")) {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .textContentType(.newPassword)
            }

            if let error = errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            }

            Section {
                Button("Create Account") {
                    register()
                }
                .disabled(firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty)
            }

            Section {
                Button("Already have an account? Log in") {
                    router.go(to: .login)
                }
            }
        }
        .navigationTitle("Register")
    }

    func register() {
        authViewModel.register(
            email: email,
            password: password,
            firstName: firstName,
            lastName: lastName
        ) { error in
            if let error = error {
                errorMessage = error.localizedDescription
            }
        }
    }
}
