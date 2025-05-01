import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

final class FirebaseService {
    static let shared = FirebaseService()

    private init() {}

    func configure() {
        guard FirebaseApp.app() == nil else {
            print("✅ Firebase already configured")
            return
        }

        FirebaseApp.configure()
        print("✅ Firebase configured successfully")

        // Optional: Setup additional services here
        _ = Auth.auth()
        _ = Firestore.firestore()
        _ = Storage.storage()
    }
}

