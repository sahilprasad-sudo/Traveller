//
//  ItineraryViewModel.swift
//  Traveller
//
//  Created by Sahil Prasad on 12/11/26.
//

import Foundation
import SwiftData
import UIKit

@Observable
final class ItineraryViewModel {
    
    /// Stored stops ko Day number aur Scheduled Time ke hisaab se chronological order me sort karta hai:
    /// - Pehle Day Number ke hisaab se sort hota hai (Day 1, Day 2, etc.)
    /// - Agar same day ke stops hain, toh unke timeString ke hisaab se sort hota hai
    func sortedStops(for trip: Trip) -> [ItineraryStop] {
        trip.stops.sorted { stopA, stopB in
            if stopA.dayNumber == stopB.dayNumber {
                return stopA.timeString < stopB.timeString
            }
            return stopA.dayNumber < stopB.dayNumber
        }
    }
    
    /// Kisi stop ka completion status toggle karta hai:
    /// - Checkmark status badalta hai (Completed / Incomplete)
    /// - SwiftData context save karta hai
    /// - Haptic feedback deta hai
    /// - Firebase cloud par naya status push karta hai taaki sabhi members ko pata chale ki checkpoint complete ho chuka hai
    func toggleStopCompletion(_ stop: ItineraryStop, in trip: Trip, modelContext: ModelContext?) {
        stop.isCompleted.toggle()
        try? modelContext?.save()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        // Firebase Cloud par automatically sync kar do
        Task {
            try? await FirebaseSyncService.shared.uploadTripToFirebase(trip: trip)
        }
    }
    
    /// Sabhi itinerary stops ko ek sath delete/clear karta hai:
    /// SwiftData aur Firebase dono se stops clear ho jate hain
    func clearAllStops(for trip: Trip, modelContext: ModelContext) {
        for stop in trip.stops {
            modelContext.delete(stop)
        }
        trip.stops.removeAll()
        
        do {
            try modelContext.save()
            
            // Firebase Cloud par automatically upload kar do
            Task {
                try? await FirebaseSyncService.shared.uploadTripToFirebase(trip: trip)
            }
        } catch {
            print("Failed to delete stops: \(error.localizedDescription)")
        }
    }
}
