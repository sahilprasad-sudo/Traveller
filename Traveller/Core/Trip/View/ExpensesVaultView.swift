//
//  ExpensesVaultView.swift
//  Traveller
//
//  Created by Sahil Prasad on 12/11/26.
//

import SwiftUI
import SwiftData

struct ExpensesVaultView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ExpensesViewModel()
    @Bindable var trip: Trip
    @State private var showingClearConfirmation: Bool = false
    @State private var showingMembersSheet: Bool = false
    
    private var settlements: [SettlementTransfer] {
        viewModel.calculateSettlements(for: trip)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Section 1: Total Group Spend Overview Card
                overviewCard
                
                // Section 2: Trip Members Overview & Management
                membersSection
                
                // Section 3: Debt Minimizer & Settlement Section
                debtSettlementSection
                
                // Section 4: Recent Expense Transactions List
                recentExpensesSection
            }
            .padding(.vertical, 16)
        }
        .sheet(isPresented: $showingMembersSheet) {
            ManageMembersSheetView(trip: trip)
        }
        .alert("Clear All Spends?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                withAnimation {
                    viewModel.clearAllSpends(for: trip, modelContext: modelContext)
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } message: {
            Text("This will mark all members as paid and clear all recorded expenses, resetting the remaining amount to ₹0.")
        }
    }
    
    private var overviewCard: some View {
        VStack(spacing: 10) {
            // Header title
            Text("TOTAL GROUP SPEND")
                .font(.caption.bold())
                .tracking(1)
                .foregroundStyle(.secondary)
            
            // Total amount formatted in Rupees (e.g. ₹17600.00)
            Text(viewModel.formatCurrency(viewModel.calculateTotalExpenses(for: trip), includeDecimals: true))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            // Kitne transactions record hue hain
            Text(trip.expenses.isEmpty ? "All spends cleared • Remaining balance: ₹0" : "\(trip.expenses.count) ledger transactions recorded")
                .font(.caption2)
                .foregroundStyle(Color.emeraldGreen)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            LinearGradient(
                colors: [Color(red: 0.11, green: 0.14, blue: 0.20), Color(red: 0.06, green: 0.08, blue: 0.11)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .padding(.horizontal, 16)
    }
    
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .foregroundStyle(Color.cyan)
                    Text("Trip Members (\(trip.members.count))")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                Button {
                    showingMembersSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Manage")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(Color.cyan)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.cyan.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(trip.members, id: \.self) { member in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.cyan.opacity(0.2))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text(String(member.prefix(1)).uppercased())
                                        .font(.caption2.bold())
                                        .foregroundStyle(Color.cyan)
                                )
                            Text(member)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                    
                    Button {
                        showingMembersSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "person.badge.plus")
                            Text("Add Person")
                        }
                        .font(.caption.bold())
                        .foregroundStyle(Color.cyan)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.cyan.opacity(0.08))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.cyan.opacity(0.2), lineWidth: 1))
                    }
                }
            }
        }
        .padding(16)
        .background(Color(red: 0.08, green: 0.10, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }
    
    private var debtSettlementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .foregroundStyle(Color.cyan)
                Text("Min-Cash-Flow Settlements")
                    .font(.headline)
                Spacer()
                Text("Greedy P2P")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
            }
            
            if settlements.isEmpty {
                // Agar sabka hisaab clear hai
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.emeraldGreen)
                    Text("All members are settled up!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                // Har ek payment transfer ka card render karte hain
                ForEach(settlements, id: \.id) { s in
                    HStack {
                        // Debtor (jo paisa dega)
                        Text(s.from)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.orange)
                        
                        // Arrow indicator
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        // Creditor (jisko paisa milega)
                        Text(s.to)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.emeraldGreen)
                        
                        Spacer()
                        
                        // Kitna amount transfer karna hai
                        Text(viewModel.formatCurrency(s.amount))
                            .font(.system(.subheadline, design: .monospaced).bold())
                            .foregroundStyle(.white)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            
            // Clear All Spends Button (indicated all users paid, remaining amount becomes zero)
            if !trip.expenses.isEmpty {
                Button {
                    showingClearConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.subheadline)
                        Text("Clear All Spends (All Paid)")
                            .font(.subheadline.bold())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color.emeraldGreen, Color(red: 0.12, green: 0.68, blue: 0.38)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color.emeraldGreen.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color(red: 0.08, green: 0.10, blue: 0.14))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }
    
    private var recentExpensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Expense Transactions")
                    .font(.headline)
                Spacer()
                if !trip.expenses.isEmpty {
                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Text("Clear All")
                            .font(.caption.bold())
                            .foregroundStyle(.red.opacity(0.85))
                    }
                }
            }
            .padding(.horizontal, 16)
            
            if trip.expenses.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "tray.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary.opacity(0.5))
                        Text("No expense transactions recorded.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            } else {
                // ViewModel se sorted transactions fetch karte hain
                ForEach(viewModel.sortedExpenses(for: trip), id: \.id) { exp in
                    HStack(spacing: 14) {
                        // Category icon circle
                        Image(systemName: exp.category.iconName)
                            .font(.system(size: 20))
                            .frame(width: 44, height: 44)
                            .background(Color.cyan.opacity(0.15))
                            .foregroundStyle(Color.cyan)
                            .clipShape(Circle())
                        
                        // Expense title aur kisne payment kiya
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exp.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white)
                            Text("Paid by \(exp.paidBy) • \(exp.category.rawValue)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        // Expense ka total amount
                        Text(viewModel.formatCurrency(exp.amount))
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(.white)
                    }
                    .padding(14)
                    .background(Color(red: 0.08, green: 0.10, blue: 0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

#Preview {
    let sampleTrip = Trip(
        title: "North Sikkim",
        subtitle: "Gangtok",
        members: ["Sahil", "Sania", "Baibhav", "Sohal"]
    )
    ExpensesVaultView(trip: sampleTrip)
        .modelContainer(for: Trip.self, inMemory: true)
}
