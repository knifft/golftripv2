import SwiftUI
import AVKit

struct FullScreenMediaView: View {
    let mediaItems: [(type: String, url: String)]
    let startingIndex: Int
    @Binding var isVisible: Bool
    @State private var currentIndex = 0

    var body: some View {
        GeometryReader { geometry in
            TabView(selection: $currentIndex) {
                ForEach(mediaItems.indices, id: \.self) { index in
                    let item = mediaItems[index]

                    ZStack {
                        Color.black.ignoresSafeArea()

                        if let url = URL(string: item.url) {
                            if item.type == "image" {
                                RemoteImageView(url: url)
                                    .scaledToFit()
                                    .frame(width: geometry.size.width)
                                    .ignoresSafeArea()
                            } else if item.type == "video" {
                                VideoPlayer(player: AVPlayer(url: url))
                                    .ignoresSafeArea()
                            }
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .background(Color.black)
            .onAppear {
                currentIndex = startingIndex
            }
            .overlay(alignment: .topTrailing) {
                Button(action: {
                    isVisible = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .padding()
                }
            }
        }
    }
}

struct RemoteImageView: View {
    let url: URL
    @State private var uiImage: UIImage? = nil
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if let image = uiImage {
                Image(uiImage: image)
                    .resizable()
            } else if isLoading {
                ProgressView()
                    .onAppear {
                        loadImage()
                    }
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .foregroundColor(.gray)
            }
        }
    }

    private func loadImage() {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.uiImage = image
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }.resume()
    }
}
