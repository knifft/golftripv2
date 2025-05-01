import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

struct NewPostView: View {
    @Environment(\.dismiss) var dismiss
    @State private var postText: String = ""
    @State private var isPosting: Bool = false

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var mediaData: [Data] = []
    @State private var mediaTypes: [String] = []
    @State private var mediaPreviews: [UIImage] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.red)

                Spacer()

                Button("Post") {
                    uploadMediaAndPost()
                }
                .disabled(postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPosting)
            }
            .padding(.horizontal)

            TextEditor(text: $postText)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary))
                .frame(minHeight: 200)

            // ✅ Media Picker
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 5,
                matching: .any(of: [.images, .videos])
            ) {
                Label("Add Media", systemImage: "photo.on.rectangle")
            }
            .onChange(of: selectedItems, initial: false) { oldItems, newItems in
                Task {
                    mediaData.removeAll()
                    mediaTypes.removeAll()
                    mediaPreviews.removeAll()

                    for item in newItems {
                        if let data = try? await item.loadTransferable(type: Data.self) {
                            mediaData.append(data)

                            if item.supportedContentTypes.contains(.movie) {
                                mediaTypes.append("video")
                            } else {
                                mediaTypes.append("image")
                                if let image = UIImage(data: data) {
                                    mediaPreviews.append(image)
                                }
                            }
                        }
                    }
                }
            }

            // ✅ Show image previews
            if !mediaPreviews.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(mediaPreviews, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipped()
                                .cornerRadius(8)
                        }
                    }
                    .padding(.top, 8)
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle("New Post")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func uploadMediaAndPost() {
        guard let user = Auth.auth().currentUser else { return }
        isPosting = true

        let db = Firestore.firestore()
        let storage = Storage.storage()
        let userId = user.uid

        db.collection("users").document(userId).getDocument { snapshot, error in
            let data = snapshot?.data()
            let authorDisplayName = data?["displayName"] as? String ?? "Unknown Golfer"
            let authorProfileImageURL = data?["profileImageURL"] as? String ?? ""

            var uploadedURLs: [String] = []
            let dispatchGroup = DispatchGroup()

            for (_, data) in mediaData.enumerated() {
                dispatchGroup.enter()
                let fileName = UUID().uuidString
                let ref = storage.reference().child("posts/\(fileName)")

                ref.putData(data) { _, error in
                    if let error = error {
                        print("🔥 Upload failed: \(error)")
                        dispatchGroup.leave()
                        return
                    }

                    ref.downloadURL { url, error in
                        if let url = url {
                            uploadedURLs.append(url.absoluteString)
                        }
                        dispatchGroup.leave()
                    }
                }
            }

            dispatchGroup.notify(queue: .main) {
                let postData: [String: Any] = [
                    "content": postText,
                    "userId": userId,
                    "authorDisplayName": authorDisplayName,
                    "authorProfileImageURL": authorProfileImageURL,
                    "timestamp": FieldValue.serverTimestamp(),
                    "likes": [],
                    "comments": [],
                    "mediaURLs": uploadedURLs,
                    "mediaTypes": mediaTypes
                ]

                db.collection("feedPosts").addDocument(data: postData) { error in
                    isPosting = false
                    if let error = error {
                        print("🔥 Failed to post: \(error.localizedDescription)")
                    } else {
                        print("✅ Firestore post uploaded successfully")
                        dismiss()
                    }
                }
            }
        }
    }
}
