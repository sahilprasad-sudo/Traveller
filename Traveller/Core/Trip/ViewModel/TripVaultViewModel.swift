//
//  TripVaultViewModel.swift
//  Traveller
//
//  Created by Sahil Prasad on 12/11/26.
//

import Foundation
import SwiftUI
import SwiftData

@Observable
final class TripVaultViewModel{
    var selectedTab: Int = 0
    var isSyncing: Bool = false
    var showingAddExpenseSheet: Bool = false
    var showingAddStopSheet: Bool = false
    var showingMembersSheet: Bool = false
    var syncStatusMessage: String = "All devices in sync"
    var lastSyncedDate: Date? = Date()
    
    func selectTab(_ index: Int) {
        withAnimation(.spring(response: 0.3)) {
            selectedTab = index
        }
    }
    
    func handlePlusButtonTap() {
        if selectedTab == 0 {
            showingAddStopSheet = true
        } else {
            showingAddExpenseSheet = true
        }
    }
    
    /// Pure trip data ko Firebase ke sath two-way sync karta hai:
    /// 1. Pehle local phone ka data cloud par upload karta hai
    /// 2. Phir cloud se naye updates fetch karke local database mein merge karta hai
    ///
    ///
    func syncWithFirebase(trip: Trip, modelContext: ModelContext) {
        // Agar pehle se sync chal raha hai toh duplicate request ignore karo
        guard !isSyncing else { return }
        
        // UI ko batao ki sync start ho gaya hai
        isSyncing = true
        syncStatusMessage = "Syncing with Firebase..."
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // Background asynchronous task run karte hain
        Task { @MainActor in
            do {
                // Step 1: Apne phone ka data cloud par upload karo
                try await FirebaseSyncService.shared.uploadTripToFirebase(trip: trip)
                
                // Step 2: Firebase se latest changes check karo aur local database mein merge karo
                if let cloudData = try await FirebaseSyncService.shared.fetchTripFromFirebase(tripId: trip.id) {
                    FirebaseSyncService.shared.mergeCloudDataIntoLocal(trip: trip, cloudData: cloudData, context: modelContext)
                }
                
                // Step 3: Success state update karo
                self.isSyncing = false
                self.syncStatusMessage = "Cloud Synced"
                self.lastSyncedDate = Date()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                // Agar internet na ho ya error aaye
                self.isSyncing = false
                self.syncStatusMessage = "Sync failed. Retry."
                print("Firebase Sync Error: \(error.localizedDescription)")
            }
        }
    }
    
    /// App pehli baar launch hone par dummy expedition load karta hai taaki screen khali na dikhe
    func seedInitialDataIfNeeded(trips: [Trip], modelContext: ModelContext) {
        // Agar pehle se trips exist karti hain toh dobara seed nahi karenge
        guard trips.isEmpty else { return }
        
        // Step 1: Nayi Trip banate hain
        let trip = Trip(
            title: "North Sikkim Expedition",
            subtitle: "Siliguri → Gangtok → Lachung → Yumthang",
            members: ["Sahil", "Rohan", "Priya", "Aman"]
        )
        modelContext.insert(trip)
        
        // Step 2: Initial Stops add karte hain
        let stop1 = ItineraryStop(
            dayNumber: 1,
            title: "Transit through Teesta Gorge",
            locationName: "NH10 Corridor",
            latitude: 26.8531,
            longitude: 88.4729,
            altitudeMeters: 400,
            timeString: "07:30 AM",
            notes: "Check road clearance before entering valley",
            category: .travel
        )
        let stop2 = ItineraryStop(
            dayNumber: 1,
            title: "Inner Line Permit & Fleet Fuel",
            locationName: "Mangan Checkpost",
            latitude: 27.5024,
            longitude: 88.5281,
            altitudeMeters: 1310,
            timeString: "01:30 PM",
            notes: "Permits inspected by ITBP",
            category: .permit
        )
        let stop3 = ItineraryStop(
            dayNumber: 2,
            title: "High Altitude Settlement Base",
            locationName: "Lachung Village",
            latitude: 27.6891,
            longitude: 88.7430,
            altitudeMeters: 2900,
            timeString: "05:00 PM",
            notes: "Acclimatize; no cellular signal",
            category: .accomodation
        )
        trip.stops.append(contentsOf: [stop1, stop2, stop3])
        
        // Step 3: Initial Group Expenses add karte hain
        let exp1 = Expense(
            title: "4x4 Fleet Diesel & Tolls",
            amount: 6400,
            paidBy: "Sahil",
            category: .transport,
            splitAmong: trip.members
        )
        let exp2 = Expense(
            title: "ITBP Military Zone Permits",
            amount: 3200,
            paidBy: "Priya",
            category: .permit,
            splitAmong: trip.members
        )
        let exp3 = Expense(
            title: "Lachung Homestay Advance",
            amount: 8000,
            paidBy: "Rohan",
            category: .stay,
            splitAmong: trip.members
        )
        trip.expenses.append(contentsOf: [exp1, exp2, exp3])
        
        // Step 4: Database mein save karte hain
        try? modelContext.save()
        
        // Step 5: Firebase Cloud par upload kar dete hain
        Task {
            try? await FirebaseSyncService.shared.uploadTripToFirebase(trip: trip)
        }
    }
}
