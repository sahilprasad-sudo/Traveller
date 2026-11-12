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
        let totalSpend = viewModel.calculateTotalExpenses(for: trip)
        let perPerson = trip.members.isEmpty ? 0 : totalSpend / Double(trip.members.count)
        
        return VStack(spacing: 12) {
            HStack {
                Text("TOTAL GROUP SPEND")
                    .font(.caption.bold())
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Label("\(trip.expenses.count) Bills", systemImage: "receipt.fill")
                    .font(.caption2.bold())
                    .foregroundStyle(Color.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cyan.opacity(0.16), in: Capsule())
            }
            
            HStack(alignment: .firstTextBaseline) {
                // Total amount formatted in Rupees (e.g. ₹17600.00)
                Text(viewModel.formatCurrency(totalSpend, includeDecimals: true))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                Spacer()
                
                if !trip.members.isEmpty {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(viewModel.formatCurrency(perPerson))
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.emeraldGreen)
                        Text("avg / person")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                }
            }
            
            // Proportional Category Spend Bar
            if totalSpend > 0 {
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        HStack(spacing: 2) {
                            ForEach(ExpensesCategory.allCases, id: \.self) { category in
                                let catTotal = trip.expenses
                                    .filter { $0.category == category }
                                    .reduce(0.0) { $0 + $1.amount }
                                if catTotal > 0 {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(expenseCategoryColor(for: category))
                                        .frame(width: max(6, geo.size.width * (catTotal / totalSpend)))
                                }
                            }
                        }
                    }
                    .frame(height: 7)
                    
                    HStack(spacing: 10) {
                        ForEach(ExpensesCategory.allCases, id: \.self) { category in
                            let hasItems = trip.expenses.contains { $0.category == category }
                            if hasItems {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(expenseCategoryColor(for: category))
                                        .frame(width: 6, height: 6)
                                    Text(category.rawValue.components(separatedBy: " ").first ?? category.rawValue)
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.75))
                                }
                            }
                        }
                        Spacer()
                    }
                }
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.emeraldGreen)
                    Text("All spends cleared • Remaining balance: ₹0")
                        .font(.caption)
                        .foregroundStyle(Color.emeraldGreen)
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.ultraThinMaterial)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.12, blue: 0.18).opacity(0.68),
                    Color(red: 0.04, green: 0.06, blue: 0.10).opacity(0.76)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.14), lineWidth: 1))
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
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 1))
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
                        .background(Color.cyan.opacity(0.10))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.cyan.opacity(0.25), lineWidth: 1))
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .background(Color(red: 0.05, green: 0.07, blue: 0.11).opacity(0.60))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12), lineWidth: 1))
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
                    .foregroundStyle(.white)
                Spacer()
                Text("Greedy P2P")
                    .font(.caption2.bold())
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.10))
                    .clipShape(Capsule())
            }
            
            if settlements.isEmpty {
                // Agar sabka hisaab clear hai
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.emeraldGreen)
                    Text("All members are settled up!")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
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
                            .foregroundStyle(.white.opacity(0.6))
                        
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
                    .background(Color.white.opacity(0.06))
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
        .background(.ultraThinMaterial)
        .background(Color(red: 0.05, green: 0.07, blue: 0.11).opacity(0.60))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12), lineWidth: 1))
        .padding(.horizontal, 16)
    }
    
    private var recentExpensesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Expense Transactions")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if !trip.expenses.isEmpty {
                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Text("Clear All")
                            .font(.caption.bold())
                            .foregroundStyle(.red.opacity(0.9))
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
                            .foregroundStyle(.white.opacity(0.45))
                        Text("No expense transactions recorded.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    .padding(.vertical, 24)
                    Spacer()
                }
            } else {
                // ViewModel se sorted transactions fetch karte hain
                ForEach(viewModel.sortedExpenses(for: trip), id: \.id) { exp in
                    let catColor = expenseCategoryColor(for: exp.category)
                    
                    HStack(spacing: 14) {
                        // Category icon circle
                        Image(systemName: exp.category.iconName)
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .background(catColor.opacity(0.18))
                            .foregroundStyle(catColor)
                            .clipShape(Circle())
                        
                        // Expense title aur kisne payment kiya
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exp.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text("Paid by \(exp.paidBy) • \(exp.category.rawValue)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.72))
                            HStack(spacing: 6) {
                                Label("Split \(max(exp.splitAmong.count, trip.members.count))", systemImage: "person.2")
                                Text("•")
                                Text(exp.date.formatted(date: .abbreviated, time: .omitted))
                            }
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.55))
                        }
                        
                        Spacer()
                        
                        // Expense ka total amount
                        Text(viewModel.formatCurrency(exp.amount))
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(.white)
                    }
                    .padding(14)
                    .background(.ultraThinMaterial)
                    .background(Color(red: 0.05, green: 0.07, blue: 0.11).opacity(0.60))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1))
                    .padding(.horizontal, 16)
                }
            }
        }
    }
    
    private func expenseCategoryColor(for category: ExpensesCategory) -> Color {
        switch category {
        case .transport: return .cyan
        case .food: return .orange
        case .permit: return .yellow
        case .stay: return .indigo
        case .emergency: return .red
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
