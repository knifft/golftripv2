import Foundation
import FirebaseFirestore

class FeedViewModel: ObservableObject {
    @Published var feedPosts: [FeedPost] = []
    @Published var userProfiles: [String: UserProfile] = [:]

    private let db = Firestore.firestore()
    private let postsCollection = "feedPosts"

    func loadPosts() {
        db.collection(postsCollection)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("No documents in feedPosts: \(error?.localizedDescription ?? "")")
                    return
                }

                self.feedPosts = documents.compactMap { doc in
                    let post = try? doc.data(as: FeedPost.self)
                    if let userId = post?.userId, !userId.isEmpty {
                        self.fetchUserProfile(userId: userId)
                    }
                    return post
                }
            }
    }

    func toggleLike(for post: FeedPost, by userId: String) {
        guard let postId = post.id else {
            print("❌ toggleLike failed: post.id was nil")
            return
        }

        let postRef = db.collection(postsCollection).document(postId)

        let hasLiked = post.likes.contains(userId)
        let update: FieldValue = hasLiked
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId])

        postRef.updateData(["likes": update])
    }

    func addComment(to post: FeedPost, commentText: String, by userId: String) {
        guard let profile = userProfiles[userId] else {
            print("❌ No profile for user \(userId)")
            return
        }

        guard let postId = post.id else {
            print("❌ addComment failed: post.id was nil")
            return
        }

        let newComment: [String: Any] = [
            "userId": userId,
            "userDisplayName": profile.displayName,
            "userProfileImageURL": profile.profileImageURL ?? "",
            "comment": commentText,
            "timestamp": Timestamp()
        ]

        db.collection(postsCollection).document(postId).updateData([
            "comments": FieldValue.arrayUnion([newComment])
        ])
    }

    func delete(post: FeedPost) {
        guard let postId = post.id else {
            print("❌ delete failed: post.id was nil")
            return
        }

        db.collection(postsCollection).document(postId).delete { error in
            if let error = error {
                print("Failed to delete post: \(error)")
            }
        }
    }

    func fetchUserProfile(userId: String) {
        print("📡 Attempting to fetch user profile for userId: \(userId)")
        guard !userId.isEmpty else {
            print("⚠️ Skipped: userId was empty")
            return
        }

        if userProfiles[userId] != nil { return }

        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("❌ Firestore error: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data(),
                  let displayName = data["displayName"] as? String else {
                print("🚫 No user profile found for ID: \(userId)")
                return
            }

            let profile = UserProfile(
                userId: userId,
                displayName: displayName,
                profileImageURL: data["profileImageURL"] as? String
            )

            DispatchQueue.main.async {
                self.userProfiles[userId] = profile
                print("✅ Loaded profile: \(displayName)")
            }
        }
    }

    func addPost(content: String, from userId: String) {
        guard let profile = userProfiles[userId] else {
            print("❌ Cannot add post — profile missing for \(userId)")
            return
        }

        let postData: [String: Any] = [
            "content": content,
            "userId": userId,
            "authorDisplayName": profile.displayName,
            "authorProfileImageURL": profile.profileImageURL ?? "",
            "timestamp": FieldValue.serverTimestamp(),
            "likes": [],
            "comments": []
        ]

        db.collection(postsCollection).addDocument(data: postData) { error in
            if let error = error {
                print("❌ Failed to create post: \(error.localizedDescription)")
            } else {
                print("✅ Post created")
            }
        }
    }
}
