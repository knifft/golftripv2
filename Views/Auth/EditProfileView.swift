import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var photoItem: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var handicap: String = ""
    @State private var homeCourse: String = ""

    @State var user: UserModel

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Profile Photo")) {
                    HStack(spacing: 16) {
                        AvatarView(name: user.displayName, imageURL: user.profileImageURL, uiImage: profileImage, size: 50)

                        PhotosPicker("Change Photo", selection: $photoItem, matching: .images)
                            .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("Handicap")) {
                    TextField("Enter your handicap", text: $handicap)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Home Course")) {
                    TextField("Enter your home course", text: $homeCourse)
                }

                Section {
                    Button("Save Changes") {
                        print("👆 Save tapped — starting update flow")
                        if let profileImage {
                            authViewModel.uploadProfileImage(profileImage) { _ in
                                print("✅ Image uploaded — now updating profile info")
                                authViewModel.updateUserProfile(
                                    handicap: handicap,
                                    homeCourse: homeCourse,
                                    profileImage: nil
                                ) {
                                    authViewModel.fetchCurrentUser()
                                    dismiss()
                                }
                            }
                        } else {
                            print("ℹ️ No image change — just updating profile info")
                            authViewModel.updateUserProfile(
                                handicap: handicap,
                                homeCourse: homeCourse,
                                profileImage: nil
                            ) {
                                authViewModel.fetchCurrentUser()
                                dismiss()
                            }
                        }
                    }
                    .disabled(handicap.isEmpty || homeCourse.isEmpty)
                }
            }
            .navigationTitle("Edit Profile")
            .onAppear {
                self.handicap = user.handicap != nil ? String(user.handicap!) : ""
                self.homeCourse = user.homeCourse ?? ""
            }
            .onChange(of: photoItem) { _, _ in
                Task {
                    if let item = photoItem,
                       let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        profileImage = image
                    }
                }
            }
        }
    }
}
