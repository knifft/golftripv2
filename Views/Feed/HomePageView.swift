import SwiftUI
import FirebaseAuth

struct HomePageView: View {
    @StateObject private var viewModel = FeedViewModel()
    @EnvironmentObject var router: NavigationRouter
    @State private var showFABOptions = false
    @State private var navigateToNewPost = false

    // Fullscreen Media Viewer State
    @State private var showMediaViewer = false
    @State private var selectedMediaIndex = 0
    @State private var selectedMediaItems: [(type: String, url: String)] = []

    private var currentUserId: String {
        Auth.auth().currentUser?.uid ?? "unknown"
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            GolftripScreen {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Activity Feed")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 40)

                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.feedPosts) { post in
                                FeedPostView(
                                    viewModel: viewModel,
                                    post: post,
                                    currentUserId: currentUserId,
                                    showMediaViewer: $showMediaViewer,
                                    selectedMediaIndex: $selectedMediaIndex,
                                    selectedMediaItems: $selectedMediaItems
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 120)
                    }
                }
                .onAppear {
                    viewModel.loadPosts()
                }
            }

            ZStack(alignment: .bottomLeading) {
                if showFABOptions {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                showFABOptions = false
                            }
                        }
                        .zIndex(1)
                }

                VStack(alignment: .leading, spacing: 12) {
                    if showFABOptions {
                        Group {
                            FloatingOption(label: "New Post", icon: "square.and.pencil")
                                .onTapGesture {
                                    router.go(to: .newPost)
                                    showFABOptions = false
                                }
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                                .animation(.spring().delay(0.0), value: showFABOptions)

                            FloatingOption(label: "New Round", icon: "flag")
                                .onTapGesture {
                                    showFABOptions = false
                                }
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                                .animation(.spring().delay(0.05), value: showFABOptions)

                            FloatingOption(label: "Upload Round", icon: "arrow.up.circle")
                                .onTapGesture {
                                    showFABOptions = false
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                        router.go(to: .uploadScorecard)
                                    }
                                }
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                                .animation(.spring().delay(0.1), value: showFABOptions)
                        }
                    }

                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            showFABOptions.toggle()
                        }
                    }) {
                        Image(systemName: showFABOptions ? "xmark" : "plus")
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(Color.accentColor))
                            .shadow(radius: 4)
                    }
                }
                .padding(.bottom, 80)
                .padding(.leading, 20)
                .zIndex(2)
            }

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
