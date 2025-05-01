import SwiftUI

// MARK: - Avatars

struct AvatarView: View {
    let name: String
    let imageURL: String?
    var uiImage: UIImage? = nil
    var size: CGFloat = 50

    var body: some View {
        if let uiImage {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .shadow(radius: 3)
        } else if let imageURL, let url = URL(string: imageURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                        .scaledToFill()
                default:
                    fallbackInitials
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .shadow(radius: 3)
        } else {
            fallbackInitials
        }
    }

    private var fallbackInitials: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: size, height: size)
            .overlay(
                Text(initials(from: name))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
            )
    }

    private func initials(from name: String) -> String {
        let parts = name.components(separatedBy: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + last).uppercased()
    }
}

// MARK: - Layout Wrappers

struct GolftripScreen<Content: View>: View {
    let content: () -> Content

    var body: some View {
        ZStack(alignment: .top) {
            Color(.systemGray6).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)
                    content()
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                }
            }

            TopNavigationBar()
                .zIndex(1)
                .padding(.top, 0)
                .background(Color.clear)
        }
    }
}

struct FloatingOption: View {
    let label: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)

            Text(label)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.accentColor)
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        )
        .transition(.asymmetric(
            insertion: .move(edge: .trailing)
                .combined(with: .opacity)
                .animation(.spring(response: 0.4, dampingFraction: 0.7)),
            removal: .opacity.animation(.easeOut(duration: 0.2))
        ))
    }
}

// MARK: - Hidden Navigation (Modern)


struct HiddenNavigationLink: View {
    var destination: NavDestination
    @Binding var isActive: Bool
    @Binding var path: NavigationPath

    var body: some View {
        Color.clear
            .onChange(of: isActive, initial: false) { _, newValue in
                if newValue {
                    path.append(destination)
                    isActive = false
                }
            }
            .frame(width: 0, height: 0)
            .zIndex(101)
    }
}
