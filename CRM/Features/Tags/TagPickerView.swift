import SwiftUI
import SwiftData

struct TagPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Tag.name) private var allTags: [Tag]
    @Binding var selectedTags: [Tag]

    @State private var newTagName = ""
    @State private var newTagColor: TagColor = .blue

    var body: some View {
        NavigationStack {
            List {
                existingTagsSection
                newTagSection
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var existingTagsSection: some View {
        Section {
            ForEach(allTags, id: \.persistentModelID) { tag in
                TagToggleRow(tag: tag, isSelected: isSelected(tag)) {
                    toggle(tag)
                }
            }
            .onDelete(perform: deleteTags)
        }
    }

    private var newTagSection: some View {
        Section("New Tag") {
            TextField("Tag name", text: $newTagName)
            Picker("Color", selection: $newTagColor) {
                ForEach(TagColor.allCases, id: \.self) { color in
                    Label(color.displayName, systemImage: "circle.fill")
                        .foregroundStyle(color.color)
                        .tag(color)
                }
            }
            Button("Create Tag") {
                createTag()
            }
            .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func isSelected(_ tag: Tag) -> Bool {
        selectedTags.contains { $0.persistentModelID == tag.persistentModelID }
    }

    private func toggle(_ tag: Tag) {
        if isSelected(tag) {
            selectedTags.removeAll { $0.persistentModelID == tag.persistentModelID }
        } else {
            selectedTags.append(tag)
        }
    }

    private func createTag() {
        let tag = Tag(name: newTagName.trimmingCharacters(in: .whitespaces), color: newTagColor)
        modelContext.insert(tag)
        selectedTags.append(tag)
        newTagName = ""
    }

    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            let tag = allTags[index]
            selectedTags.removeAll { $0.persistentModelID == tag.persistentModelID }
            modelContext.delete(tag)
        }
    }
}

struct TagToggleRow: View {
    let tag: Tag
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                TagChipView(tag: tag)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
        }
        .foregroundStyle(.primary)
    }
}
