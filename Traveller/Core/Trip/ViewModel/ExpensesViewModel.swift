//
//  ExpensesSheetViewModel.swift
//  Traveller
//
//  Created by Sahil Prasad on 12/11/26.
//

import Foundation
import SwiftData

@Observable
final class ExpensesViewModel {
    
    /// Trip ke sabhi recorded expenses ka total sum nikalta hai:
    func calculateTotalExpenses(for trip: Trip) -> Double {
        return trip.expenses.reduce(0.0) { runningTotal, currentExpenses in
            runningTotal + currentExpenses.amount
        }
    }
    
    func calculateSettlements(for trip: Trip) -> [SettlementTransfer] {
        return SettlementEngine.calculateSettlment(
            members: trip.members,
            expenses: trip.expenses
        )
    }
    
    // Expenses ko date ke hisaab se descending order (sabse latest kharcha upar) mein sort karta hai
    func sortedExpenses(for trip: Trip) -> [Expense] {
        return trip.expenses.sorted { expenseA, expenseB in
            expenseA.date > expenseB.date
        }
    }
    
    // Currency Formatter
    func formatCurrency(_ amount: Double, includeDecimals: Bool = false) -> String {
        if includeDecimals {
            return "₹\(String(format: "%.2f", amount))"
        } else {
            return "₹\(String(format: "%.0f", amount))"
        }
    }
    
    /// Sabhi expenses ko ek sath clear karta hai (indicating all users have paid):
    /// SwiftData aur Firebase dono se expenses clear ho jate hain aur remaining balance 0 ho jata hai.
    func clearAllSpends(for trip: Trip, modelContext: ModelContext) {
        for expense in trip.expenses {
            modelContext.delete(expense)
        }
        trip.expenses.removeAll()
        
        do {
            try modelContext.save()
            
            // Firebase Cloud par automatically upload kar do
            Task {
                try? await FirebaseSyncService.shared.uploadTripToFirebase(trip: trip)
            }
        } catch {
            print("Failed to clear expenses: \(error.localizedDescription)")
        }
    }
}
