//
//  ManageMembersSheetView.swift
//  Traveller
//
//  Created by Sahil Prasad on 12/11/26.
//

import SwiftUI
import SwiftData

struct ManageMembersSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var trip: Trip
    
    @State private var newMemberName: String = ""
    @State private var alertMessage: String?
    @State private var showingAlert: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.03, green: 0.04, blue: 0.06).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Section 1: Add New Member Card
                        addMemberCard
                        
                        // Section 2: Members Count & List
                        membersListCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Expedition Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.cyan)
                    .fontWeight(.semibold)
                }
            }
            .alert("Notice", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if let message = alertMessage {
                    Text(message)
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var addMemberCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Add New Member", systemImage: "person.badge.plus")
                .font(.headline)
                .foregroundStyle(Color.cyan)
            
            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .foregroundStyle(.secondary)
                    
                    TextField("Enter name (e.g. Rohan, Sneha)", text: $newMemberName)
                        .foregroundStyle(.white)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .onSubmit {
                            addNewMember()
                        }
                }
                .padding(12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                Button {
                    addNewMember()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(isInputValid ? Color.cyan : Color.gray.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(!isInputValid)
            }
        }
        .padding(16)
        .background(Color(red: 0.08, green: 0.10, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var membersListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Current Members", systemImage: "person.2.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text("\(trip.members.count) people")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .foregroundStyle(.secondary)
            }
            
            if trip.members.isEmpty {
                Text("No members in this expedition yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 8) {
                    ForEach(trip.members, id: \.self) { member in
                        HStack(spacing: 12) {
                            // Avatar Circle
                            Circle()
                                .fill(avatarGradient(for: member))
                                .frame(width: 38, height: 38)
                                .overlay(
                                    Text(String(member.prefix(1)).uppercased())
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.white)
                                )
                            
                            Text(member)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            // Delete Button (only if more than 1 member remains)
                            if trip.members.count > 1 {
                                Button(role: .destructive) {
                                    removeMember(member)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.subheadline)
                                        .foregroundStyle(.red.opacity(0.8))
                                        .padding(8)
                                        .background(Color.red.opacity(0.1))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            
            Text("Members are automatically included in equal expense splits and settlement calculations.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding(16)
        .background(Color(red: 0.08, green: 0.10, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Helper Methods
    
    private var isInputValid: Bool {
        let clean = newMemberName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !clean.isEmpty
    }
    
    private func addNewMember() {
        let clean = newMemberName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        
        if trip.members.contains(where: { $0.caseInsensitiveCompare(clean) == .orderedSame }) {
            alertMessage = "\(clean) is already a member of this trip."
            showingAlert = true
            return
        }
        
        withAnimation {
            var updated = trip.members
            updated.append(clean)
            trip.members = updated
            newMemberName = ""
        }
        
        saveAndSync()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func removeMember(_ member: String) {
        guard trip.members.count > 1 else {
            alertMessage = "A trip must have at least one member."
            showingAlert = true
            return
        }
        
        withAnimation {
            var updated = trip.members
            updated.removeAll { $0 == member }
            trip.members = updated
        }
        
        saveAndSync()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func saveAndSync() {
        do {
            try modelContext.save()
            Task {
                try? await FirebaseSyncService.shared.uploadTripToFirebase(trip: trip)
            }
        } catch {
            print("Failed to save members: \(error.localizedDescription)")
        }
    }
    
    private func avatarGradient(for name: String) -> LinearGradient {
        let hash = abs(name.hashValue)
        let colors: [[Color]] = [
            [.cyan, Color(red: 0.1, green: 0.5, blue: 0.8)],
            [.emeraldGreen, Color(red: 0.1, green: 0.6, blue: 0.3)],
            [.orange, Color(red: 0.9, green: 0.4, blue: 0.1)],
            [.purple, Color(red: 0.6, green: 0.2, blue: 0.8)],
            [.pink, Color(red: 0.8, green: 0.2, blue: 0.5)]
        ]
        let selected = colors[hash % colors.count]
        return LinearGradient(colors: selected, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

#Preview {
    let trip = Trip(
        title: "North Sikkim",
        members: ["Sahil", "Sania", "Baibhav", "Sohal"]
    )
    ManageMembersSheetView(trip: trip)
        .modelContainer(for: Trip.self, inMemory: true)
}
