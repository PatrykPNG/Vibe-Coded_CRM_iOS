import SwiftUI
import SwiftData

struct ContactFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var contact: Contact?

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var company = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var notes = ""
    @State private var selectedTags: [Tag] = []
    @State private var showingTagPicker = false

    private var isEditing: Bool { contact != nil }
    private var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty ||
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("First name", text: $firstName)
                        .textContentType(.givenName)
                    TextField("Last name", text: $lastName)
                        .textContentType(.familyName)
                }

                Section("Details") {
                    TextField("Company", text: $company)
                        .textContentType(.organizationName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }

                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(4...)
                }

                Section {
                    if !selectedTags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(selectedTags) { tag in
                                    TagChipView(tag: tag)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    Button("Manage Tags", systemImage: "tag") {
                        showingTagPicker = true
                    }
                } header: {
                    Text("Tags")
                }
            }
            .navigationTitle(isEditing ? "Edit Contact" : "New Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isFormValid)
                }
            }
            .onAppear { populateFields() }
            .sheet(isPresented: $showingTagPicker) {
                TagPickerView(selectedTags: $selectedTags)
            }
        }
    }

    private func populateFields() {
        guard let contact else { return }
        firstName = contact.firstName
        lastName = contact.lastName
        company = contact.company
        email = contact.email
        phone = contact.phone
        notes = contact.notes
        selectedTags = contact.tags ?? []
    }

    private func save() {
        if let contact {
            contact.firstName = firstName
            contact.lastName = lastName
            contact.company = company
            contact.email = email
            contact.phone = phone
            contact.notes = notes
            contact.tags = selectedTags
        } else {
            let newContact = Contact(
                firstName: firstName,
                lastName: lastName,
                company: company,
                email: email,
                phone: phone,
                notes: notes
            )
            newContact.tags = selectedTags
            modelContext.insert(newContact)
        }
        dismiss()
    }
}
