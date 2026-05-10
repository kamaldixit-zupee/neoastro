import SwiftUI
import UIKit
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @State var profile: UserDetails
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var gender: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: Field?

    // Profile picture upload
    @State private var pickedItem: PhotosPickerItem?
    @State private var pickedImageData: Data?
    @State private var uploadedPictureURL: URL?
    @State private var isUploadingPicture: Bool = false
    @State private var uploadErrorMessage: String?

    enum Field { case name, email, gender, city, state }

    var onSaved: (() -> Void)? = nil

    var body: some View {
        ZStack {
            CosmicBackground()

            ScrollView {
                VStack(spacing: 14) {
                    avatarSection
                        .padding(.bottom, 4)

                    fieldRow("Name", text: $name, field: .name, keyboard: .default, contentType: .name)
                    fieldRow("Email", text: $email, field: .email, keyboard: .emailAddress, contentType: .emailAddress)
                    fieldRow("Gender", text: $gender, field: .gender, keyboard: .default, contentType: .none)
                    fieldRow("City", text: $city, field: .city, keyboard: .default, contentType: .addressCity)
                    fieldRow("State", text: $state, field: .state, keyboard: .default, contentType: .addressState)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity)
                    }

                    Button {
                        Task { await save() }
                    } label: {
                        HStack(spacing: 10) {
                            if isSaving { ProgressView().tint(.white) }
                            Text(isSaving ? "Saving…" : "Save Changes")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .tint(AppTheme.pinkAccent)
                    .disabled(isSaving)
                    .padding(.top, 8)
                }
                .padding(20)
                .padding(.bottom, 80)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .font(.body.weight(.semibold))
            }
        }
        .onAppear {
            name = profile.name ?? ""
            email = profile.email ?? ""
            gender = profile.gender ?? ""
            city = profile.city ?? ""
            state = profile.state ?? ""
        }
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                avatarView

                PhotosPicker(selection: $pickedItem, matching: .images) {
                    Image(systemName: isUploadingPicture ? "ellipsis" : "camera.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .glassEffect(.regular.tint(AppTheme.pinkAccent.opacity(0.6)), in: .circle)
                }
                .disabled(isUploadingPicture)
                .onChange(of: pickedItem) { _, newValue in
                    guard let newValue else { return }
                    Task { await loadAndUpload(newValue) }
                }
            }

            if isUploadingPicture {
                Text("Uploading…")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            if let uploadErrorMessage {
                Text(uploadErrorMessage)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        let displayURL = uploadedPictureURL
            ?? profile.profilePictureUrl.flatMap(URL.init(string:))

        AvatarView(
            name: profile.name ?? "User",
            imageURL: displayURL,
            gradient: AppTheme.primaryAvatarPalette,
            size: 110
        )
        .overlay {
            if isUploadingPicture {
                Circle().fill(.black.opacity(0.45))
                ProgressView().tint(.white)
            }
        }
        .clipShape(Circle())
    }

    @MainActor
    private func loadAndUpload(_ item: PhotosPickerItem) async {
        uploadErrorMessage = nil
        isUploadingPicture = true
        defer {
            isUploadingPicture = false
            pickedItem = nil
        }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                uploadErrorMessage = "Couldn't read that image"
                return
            }
            pickedImageData = data
            let url = try await ProfileService.uploadProfilePic(imageData: data)
            uploadedPictureURL = url
            onSaved?()   // refresh profile in caller so the new URL sticks
        } catch {
            AppLog.error(.account, "profile pic upload failed", error: error)
            uploadErrorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }

    // MARK: - Fields

    private func fieldRow(_ label: String, text: Binding<String>, field: Field, keyboard: UIKeyboardType, contentType: UITextContentType?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))

            TextField("", text: text, prompt: Text(label).foregroundColor(.white.opacity(0.45)))
                .keyboardType(keyboard)
                .textContentType(contentType)
                .focused($focusedField, equals: field)
                .font(.body)
                .foregroundStyle(.white)
                .tint(AppTheme.pinkAccent)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: .capsule)
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        let payload = EditProfilePayload(
            name: name.isEmpty ? nil : name,
            email: email.isEmpty ? nil : email,
            dateOfBirth: profile.dateOfBirth,
            gender: gender.isEmpty ? nil : gender,
            city: city.isEmpty ? nil : city,
            state: state.isEmpty ? nil : state,
            profilePictureUrl: uploadedPictureURL?.absoluteString
        )
        do {
            try await ProfileService.submit(payload)
            onSaved?()
            dismiss()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        isSaving = false
    }
}
