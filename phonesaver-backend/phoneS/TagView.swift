import SwiftUI

struct TagView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let contact: Contact
    @State private var newTag: String = ""
    @State private var isAddingTag = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tags")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(contact.tags, id: \.self) { tag in
                        TagChip(tag: tag) {
                            var updatedTags = contact.tags
                            updatedTags.removeAll { $0 == tag }
                            authViewModel.updateTags(for: contact.id, tags: updatedTags)
                        }
                    }
                    
                    if isAddingTag {
                        TextField("New tag", text: $newTag)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                            .onSubmit {
                                addTag()
                            }
                    }
                    
                    Button(action: {
                        withAnimation {
                            isAddingTag.toggle()
                            if !isAddingTag {
                                newTag = ""
                            }
                        }
                    }) {
                        Image(systemName: isAddingTag ? "xmark.circle.fill" : "plus.circle.fill")
                            .foregroundColor(isAddingTag ? .red : .blue)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty && !contact.tags.contains(tag) {
            var updatedTags = contact.tags
            updatedTags.append(tag)
            authViewModel.updateTags(for: contact.id, tags: updatedTags)
            newTag = ""
            isAddingTag = false
        }
    }
}

struct TagChip: View {
    let tag: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.subheadline)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(15)
    }
}

struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        TagView(contact: Contact(id: 1, name: "John Doe", encryptedPhone: "encrypted"))
            .environmentObject(AuthViewModel())
    }
} 