import SwiftUI
import UIKit

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

    enum Field { case name, email, gender, city, state }

    var onSaved: (() -> Void)? = nil

    var body: some View {
        ZStack {
            CosmicBackground()

            ScrollView {
                VStack(spacing: 14) {
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
            state: state.isEmpty ? nil : state
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
