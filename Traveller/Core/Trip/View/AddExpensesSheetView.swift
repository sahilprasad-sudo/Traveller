//
//  AddExpensesSheetView.swift
//  Traveller
//
//  Created by Sahil Prasad on 12/11/26.
//

import SwiftUI
import SwiftData

struct AddExpensesSheetView: View {
    
    @Environment(\.dismiss) private var dismiss
    // SwiftData database context (database mein naya expense add karne ke liye)
    @Environment(\.modelContext) private var modelContext
    var trip: Trip
    @State private var viewModel = AddExpenseViewModel()
    @State private var selectedMembers: [String] = []
    @State private var showingAddMemberAlert: Bool = false
    @State private var newMemberName: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Expense Details (Description, Amount, Category)
                Section("Expense Details") {
                    TextField("Description (e.g. Lunch at Manish Dhaba)", text: $viewModel.title)
                    
                    TextField("₹ Total Amount Paid", text: $viewModel.amountString)
                        .keyboardType(.decimalPad)
                    
                    Picker("Category", selection: $viewModel.category) {
                        ForEach(ExpensesCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.iconName).tag(cat)
                        }
                    }
                }
                
                // Section 2: Payer (Kisne payment kiya)
                Section {
                    Picker("Paid By", selection: $viewModel.paidBy) {
                        ForEach(trip.members, id: \.self) { member in
                            Text(member).tag(member)
                        }
                    }
                    
                    Button {
                        showingAddMemberAlert = true
                    } label: {
                        Label("Add New Person to Trip", systemImage: "person.badge.plus")
                            .font(.subheadline)
                            .foregroundStyle(Color.cyan)
                    }
                } header: {
                    Text("Payer")
                }
                
                // Section 3: Split Distribution Information
                Section {
                    HStack {
                        Text("Split Among (\(selectedMembers.count) of \(trip.members.count))")
                            .font(.subheadline)
                        Spacer()
                        Button(selectedMembers.count == trip.members.count ? "Deselect Others" : "All Members") {
                            if selectedMembers.count == trip.members.count {
                                if let first = trip.members.first {
                                    selectedMembers = [first]
                                }
                            } else {
                                selectedMembers = trip.members
                            }
                        }
                        .font(.caption.bold())
                    }
                    
                    ForEach(trip.members, id: \.self) { member in
                        Button {
                            toggleMember(member)
                        } label: {
                            HStack {
                                Text(member)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedMembers.contains(member) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.cyan)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    if let amount = Double(viewModel.amountString), amount > 0, !selectedMembers.isEmpty {
                        let perPerson = amount / Double(selectedMembers.count)
                        Text("₹\(String(format: "%.2f", perPerson)) per person")
                            .font(.caption.bold())
                            .foregroundStyle(Color.emeraldGreen)
                    }
                } header: {
                    Text("Split Distribution")
                } footer: {
                    Text("Expense will be divided equally among all selected members.")
                        .font(.caption)
                }
            }
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Add Person to Trip", isPresented: $showingAddMemberAlert) {
                TextField("Member Name", text: $newMemberName)
                Button("Add") {
                    let clean = newMemberName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !clean.isEmpty && !trip.members.contains(clean) {
                        var updated = trip.members
                        updated.append(clean)
                        trip.members = updated
                        selectedMembers.append(clean)
                        viewModel.paidBy = clean
                        newMemberName = ""
                        try? modelContext.save()
                        Task {
                            try? await FirebaseSyncService.shared.uploadTripToFirebase(trip: trip)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    newMemberName = ""
                }
            } message: {
                Text("Enter the name of the new person to include in this expedition.")
            }
            .onAppear {
                viewModel.setupInitialPayer(from: trip)
                if selectedMembers.isEmpty {
                    selectedMembers = trip.members
                }
            }
            .toolbar {
                // Cancel button: Form discard karke sheet close karta hai
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                // Save button: Expense validate karke save aur cloud upload karta hai
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.addExpense(to: trip, splitAmong: selectedMembers, modelContext: modelContext) {
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isAmountValid)
                }
            }
        }
    }
    
    private func toggleMember(_ member: String) {
        if selectedMembers.contains(member) {
            if selectedMembers.count > 1 {
                selectedMembers.removeAll { $0 == member }
            }
        } else {
            selectedMembers.append(member)
        }
    }
}

#Preview {
    AddExpensesSheetView(trip: Trip())
}
