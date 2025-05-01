import FirebaseAuth
import Foundation
import FirebaseFirestore
import FirebaseStorage
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isLoggedIn = false
    @Published var currentUser: UserModel?

    init() {
        self.isLoggedIn = Auth.auth().currentUser != nil
        if isLoggedIn {
            fetchCurrentUser()
        }
    }

    func login(email: String, password: String) {
        print("Attempting login with: \(email)")
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                print("Login error: \(error.localizedDescription)")
            } else if let user = result?.user {
                print("Login succeeded")
                DispatchQueue.main.async {
                    self?.isLoggedIn = true
                    self?.fetchCurrentUser()
                }

                let db = Firestore.firestore()
                let docRef = db.collection("users").document(user.uid)
                docRef.getDocument { docSnapshot, error in
                    if let doc = docSnapshot, !doc.exists {
                        print("Creating missing Firestore user doc...")
                        docRef.setData([
                            "uid": user.uid,
                            "email": user.email ?? "",
                            "firstName": "",
                            "lastName": "",
                            "createdAt": FieldValue.serverTimestamp(),
                            "lastLogin": FieldValue.serverTimestamp(),
                            "role": "member",
                            "handicap": NSNull(),
                            "homeCourse": NSNull(),
                            "trips": [],
                            "stats": [
                                "totalRounds": 0,
                                "lowestScore": NSNull(),
                                "averageScore": NSNull()
                            ],
                            "rivals": [],
                            "rivalryIds": []
                        ])
                    }
                }
            }
        }
    }

    func register(email: String, password: String, firstName: String, lastName: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                print("Registration error: \(error.localizedDescription)")
                completion(error)
                return
            }

            guard let user = result?.user else {
                completion(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user returned from Firebase"]))
                return
            }

            let db = Firestore.firestore()
            let docRef = db.collection("users").document(user.uid)
            docRef.setData([
                "uid": user.uid,
                "email": email,
                "firstName": firstName,
                "lastName": lastName,
                "createdAt": FieldValue.serverTimestamp(),
                "lastLogin": FieldValue.serverTimestamp(),
                "role": "member",
                "handicap": NSNull(),
                "homeCourse": NSNull(),
                "trips": [],
                "stats": [
                    "totalRounds": 0,
                    "lowestScore": NSNull(),
                    "averageScore": NSNull()
                ],
                "rivals": [],
                "rivalryIds": []
            ]) { error in
                if let error = error {
                    print("Error creating Firestore user: \(error.localizedDescription)")
                }
            }

            DispatchQueue.main.async {
                self?.isLoggedIn = true
                self?.fetchCurrentUser()
            }

            completion(nil)
        }
    }

    func uploadProfileImage(_ image: UIImage, completion: @escaping (URL?) -> Void) {
        print("📸 uploadProfileImage called")

        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ No current user ID — cannot upload.")
            completion(nil)
            return
        }

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert image to JPEG data")
            completion(nil)
            return
        }

        let storage = Storage.storage(url: "gs://golftrip-new.firebasestorage.app") // ✅ Explicit bucket
        let storageRef = storage.reference().child("profileImages/\(uid).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        print("📤 Starting upload to: \(storageRef.fullPath)")
        print("📦 Image data size: \(imageData.count) bytes")

        storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("❌ Upload error: \(error.localizedDescription)")
                completion(nil)
                return
            }

            print("✅ Upload complete. Getting download URL...")

            storageRef.downloadURL { url, error in
                if let url = url {
                    print("✅ Got download URL: \(url.absoluteString)")
                    self.updateProfileImageURL(url)
                }

                guard let url = url else {
                    print("❌ No URL returned after upload")
                    completion(nil)
                    return
                }

                print("✅ Got download URL: \(url.absoluteString)")
                print("🧪 Saving this profileImageURL to Firestore: \(url.absoluteString)")
                self.updateProfileImageURL(url)
                completion(url)
            }
        }
    }



    private func updateProfileImageURL(_ url: URL) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData([
            "profileImageURL": url.absoluteString
        ]) { error in
            if let error = error {
                print("❌ Failed to save profileImageURL: \(error)")
            } else {
                print("✅ Saved profileImageURL to Firestore: \(url.absoluteString)")
                self.fetchCurrentUser()
            }
        }
    }


    func updateUserProfile(handicap: String, homeCourse: String, profileImage: UIImage?, completion: @escaping () -> Void) {
        guard let user = Auth.auth().currentUser else { return }

        let db = Firestore.firestore()
        let data: [String: Any] = [
            "handicap": Double(handicap) ?? NSNull(),
            "homeCourse": homeCourse
        ]

        db.collection("users").document(user.uid).updateData(data) { error in
            if let error = error {
                print("❌ Error updating profile info: \(error.localizedDescription)")
            } else {
                print("✅ Profile info updated (handicap, homeCourse)")
            }

            if let image = profileImage {
                print("🖼 Uploading new profile image...")
                self.uploadProfileImage(image) { _ in
                    print("✅ Profile image upload complete.")
                    completion()
                }
            } else {
                completion()
            }
        }
    }

    func fetchCurrentUser() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ No UID — not logged in?")
            return
        }

        print("📡 Fetching Firestore doc for UID: \(uid)")
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user profile: \(error.localizedDescription)")
                return
            }

            guard let snapshot = snapshot, snapshot.exists else {
                print("❌ User document does not exist in Firestore.")
                return
            }


            do {
                let user = try snapshot.data(as: UserModel.self)
                DispatchQueue.main.async {
                    self.currentUser = user
                }
            } catch {
                print("Error decoding user: \(error)")
            }
        }
    }

    func goHome() {
        print("Navigate to Home — placeholder")
    }

    func goToProfile() {
        print("Navigate to Profile — placeholder")
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.currentUser = nil
            }
            print("User signed out successfully")
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}
