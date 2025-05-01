import Foundation
import FirebaseAuth
import FirebaseFirestore

class ProfileViewModel: ObservableObject {
    @Published var user: UserModel?

    func fetchCurrentUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user: \(error)")
                return
            }

            if let data = try? snapshot?.data(as: UserModel.self) {
                DispatchQueue.main.async {
                    self.user = data
                }
            }
        }
    }
}
