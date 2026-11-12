//
//  SettlementManager.swift
//  Traveller
//
//  Created by Sahil Prasad on 12/11/26.
//

import Foundation

struct SettlementTransfer:Identifiable{
    let id = UUID()
    let from:String
    let to:String
    let amount:Double
    
}

struct SettlementEngine{
    static func calculateSettlment(members:[String],expenses:[Expense]) -> [SettlementTransfer]{
        var balances:[String:Double] = [:]
        
        for eachMember in members {
            balances[eachMember] = 0.0
        }
        
        for expense in expenses {
            let splitCount = expense.splitAmong.isEmpty ? members.count : expense.splitAmong.count
            guard splitCount > 0 else{
                continue
            }
            
            let share = expense.amount / Double(splitCount) //har aadmi ka share
            
            balances[expense.paidBy,default: 0.0] += expense.amount //jisne pay kiye uske uske accout ko credit krna
            
            let remainingPeople = expense.splitAmong.isEmpty ? members : expense.splitAmong
            
            //jis jis m split hona thaa unke balance m se unka amount deduct krna
            for target in remainingPeople {
                balances[target,default: 0.0] -= share
            }
            
        }
        //sbb kuch hone k baad kuch log aise v honge jinko paise dene honge qki unhone jyda pay kiya thaa
        var debtors:[(name:String,amount:Double)] = []
        var creditors:[(name:String,amount:Double)] = []
        
        for(name,balance) in balances{
            if(balance < -0.01){
                debtors.append((name,-balance)) //balance ko positive bna kr store krte h
            }
            else if(balance > 0.01){
                // Agar balance positive hai toh wo Creditor hai (unhe paise milne hain)
                creditors.append((name,balance))
            }
        }
        // Line 5: Badi amounts ko pehle settle karne ke liye descending order mein sort karte hain (Greedy Approach)
        debtors.sort{ $0.amount > $1.amount}
        creditors.sort{ $0.amount > $1.amount}
        
        // Transfers store karne ke liye array
        var transfers: [SettlementTransfer] = []
        var dIdx = 0 // Debtors pointer
        var cIdx = 0 // Creditors pointer
        
        // Line 6: Two-pointer loop se minimum transactions create karte hain
        while dIdx < debtors.count && cIdx < creditors.count {
            let debtor = debtors[dIdx]
            let creditor = creditors[cIdx]
            
            // Dono mein se jo amount choti hogi, utna transfer create hoga
            let settlementAmount = min(debtor.amount, creditor.amount)
            if settlementAmount > 0.01 {
                transfers.append(SettlementTransfer(from: debtor.name, to: creditor.name, amount: settlementAmount))
            }
            
            // Dena baki amount kam karte hain
            debtors[dIdx].amount -= settlementAmount
            creditors[cIdx].amount -= settlementAmount
            
            // Agar debtor ka pura paisa chuk gaya, toh next debtor par badho
            if debtors[dIdx].amount <= 0.01 { dIdx += 1 }
            // Agar creditor ko uska pura paisa mil gaya, toh next creditor par badho
            if creditors[cIdx].amount <= 0.01 { cIdx += 1 }
        }
        return transfers
    }
}
