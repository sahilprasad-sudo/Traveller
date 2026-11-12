//
//  AddExpenseViewModel.swift
//  Traveller
//
//  Created by Sahil Prasad on 12/11/26.
//

import Foundation
import SwiftUI
import SwiftData

@Observable
final class AddExpenseViewModel {
    var title: String = ""
    var amountString: String = ""
    var paidBy: String = ""
    var category: ExpensesCategory = .food
    var splitAmong: [String] = []
    
    // Sheet open hone par default payer aur split members set karta hai
    func setupInitialPayer(from trip: Trip) {
        if paidBy.isEmpty, let firstMember = trip.members.first {
            paidBy = firstMember
        }
        if splitAmong.isEmpty {
            splitAmong = trip.members
        }
    }
    
    func toggleSplitMember(_ member: String) {
        if splitAmong.contains(member) {
            if splitAmong.count > 1 {
                splitAmong.removeAll { $0 == member }
            }
        } else {
            splitAmong.append(member)
        }
    }
    
    func selectAllMembers(from trip: Trip) {
        splitAmong = trip.members
    }
    
    var isAmountValid: Bool {
        guard let amount = Double(amountString), amount > 0 else {
            return false
        }
        return true
    }
    
    /// Naye expense ko trip me record, SwiftData me save, aur Firebase par upload karta hai
    func addExpense(
        to trip: Trip,
        splitAmong customSplit: [String]? = nil,
        modelContext: ModelContext,
        onSuccess: () -> Void
    ) {
        guard let amount = Double(amountString), amount > 0 else { return }
        
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveSplit: [String]
        if let custom = customSplit, !custom.isEmpty {
            effectiveSplit = custom
        } else if !self.splitAmong.isEmpty {
            effectiveSplit = self.splitAmong
        } else {
            effectiveSplit = trip.members
        }
        
        let newExp = Expense(
            title: cleanTitle.isEmpty ? "Group Expense" : cleanTitle,
            amount: amount,
            paidBy: paidBy.isEmpty ? (trip.members.first ?? "Unknown") : paidBy,
            category: category,
            splitAmong: effectiveSplit
        )
        
        trip.expenses.append(newExp)
        
        do {
            try modelContext.save()
            
            // Firebase Cloud par automatically upload kar do
            Task {
                try? await FirebaseSyncService.shared.uploadTripToFirebase(trip: trip)
            }
            
            onSuccess()
        } catch {
            print("Failed to save expense: \(error.localizedDescription)")
        }
    }
}
