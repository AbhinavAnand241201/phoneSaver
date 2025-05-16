import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let contact: Contact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Insights")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                InsightRow(
                    title: "Last Contact",
                    value: contact.lastContactDate?.formatted(date: .abbreviated, time: .shortened) ?? "Never",
                    icon: "clock"
                )
                
                InsightRow(
                    title: "Contact Frequency",
                    value: contact.contactFrequency,
                    icon: "chart.bar"
                )
                
                InsightRow(
                    title: "Preferred Time",
                    value: contact.preferredTime ?? "Not available",
                    icon: "calendar"
                )
                
                if let notes = contact.notes, !notes.isEmpty {
                    InsightRow(
                        title: "Notes",
                        value: notes,
                        icon: "note.text"
                    )
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
    }
}

struct InsightRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.body)
            }
        }
    }
}

struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        InsightsView(contact: Contact(
            id: 1,
            name: "John Doe",
            encryptedPhone: "encrypted",
            lastContactDate: Date(),
            contactFrequency: "Weekly",
            preferredTime: "Evenings",
            notes: "Prefers text messages"
        ))
        .environmentObject(AuthViewModel())
        .padding()
    }
} 