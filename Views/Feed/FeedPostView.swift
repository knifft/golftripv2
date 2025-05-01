import SwiftUI
import FirebaseFirestore
import AVKit

struct FeedPostView: View {
    let viewModel: FeedViewModel
    let post: FeedPost
    let currentUserId: String
    
    // Pass-through bindings
    @Binding var showMediaViewer: Bool
    @Binding var selectedMediaIndex: Int
    @Binding var selectedMediaItems: [(type: String, url: String)]

    init(
        viewModel: FeedViewModel,
        post: FeedPost,
        currentUserId: String,
        showMediaViewer: Binding<Bool>,
        selectedMediaIndex: Binding<Int>,
        selectedMediaItems: Binding<[(type: String, url: String)]>
    ) {
        self.viewModel = viewModel
        self.post = post
        self.currentUserId = currentUserId
        self._showMediaViewer = showMediaViewer
        self._selectedMediaIndex = selectedMediaIndex
        self._selectedMediaItems = selectedMediaItems
    }


    @State private var showComments = false
    @State private var newCommentText = ""


    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                // Post Author
                HStack {
                    AvatarView(name: post.authorDisplayName, imageURL: post.authorProfileImageURL, size: 36)

                    Text(post.authorDisplayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    Text(post.timestamp.dateValue(), style: .time)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                // Post Content
                Text(post.content)
                    .font(.body)
                    .padding(.top, 2)

                // Media Section
                if let urls = post.mediaURLs, let types = post.mediaTypes {
                    let mediaItems = Array(zip(types, urls))

                    if mediaItems.count == 1, let item = mediaItems.first, item.0 == "image", let url = URL(string: item.1) {
                        RemoteImageView(url: url)
                            .scaledToFit()
                            .cornerRadius(8)
                            .onTapGesture {
                                selectedMediaIndex = 0
                                selectedMediaItems = mediaItems
                                showMediaViewer = true
                            }
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(mediaItems.indices, id: \.self) { index in
                                let item = mediaItems[index]
                                if item.0 == "image", let url = URL(string: item.1) {
                                    RemoteImageView(url: url)
                                        .scaledToFill()
                                        .frame(height: 120)
                                        .clipped()
                                        .cornerRadius(6)
                                        .onTapGesture {
                                            selectedMediaIndex = index
                                            selectedMediaItems = mediaItems
                                            showMediaViewer = true
                                        }
                                }
                            }
                        }
                    }
                }

                // Buttons
                HStack {
                    Button(action: {
                        viewModel.toggleLike(for: post, by: currentUserId)
                    }) {
                        HStack {
                            Image(systemName: post.likes.contains(currentUserId) ? "hands.clap.fill" : "hands.clap")
                            Text("\(post.likes.count)")
                        }
                    }

                    Button(action: {
                        withAnimation {
                            showComments.toggle()
                        }
                    }) {
                        HStack {
                            Image(systemName: "bubble.right")
                            Text("\(post.comments.count)")
                        }
                    }

                    Spacer()

                    if post.userId == currentUserId {
                        Button(action: {
                            viewModel.delete(post: post)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                .font(.caption)

                // Comments Section
                if showComments {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(post.comments) { comment in
                            HStack(alignment: .top, spacing: 8) {
                                AvatarView(name: comment.userDisplayName, imageURL: comment.userProfileImageURL, size: 28)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(comment.userDisplayName)
                                        .font(.caption)
                                        .fontWeight(.semibold)

                                    Text(comment.comment)
                                        .font(.subheadline)

                                    Text(comment.timestamp.dateValue(), style: .time)
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                        }

                        // Add New Comment
                        HStack {
                            TextField("Add a comment...", text: $newCommentText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            Button("Send") {
                                guard !newCommentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                                viewModel.addComment(to: post, commentText: newCommentText, by: currentUserId)
                                newCommentText = ""
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(radius: 1)

            // Fullscreen Viewer Overlay
            if showMediaViewer {
                FullScreenMediaView(
                    mediaItems: selectedMediaItems,
                    startingIndex: selectedMediaIndex,
                    isVisible: $showMediaViewer
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
    }
}
