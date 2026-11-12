//
//  AddCheckpostModel.swift
//  Traveller
//
//  Created by Sahil Prasad on 12/11/26.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
final class AddCheckpostModel{
    var title:String = ""
    var locationName:String = ""
    var dayNumber:Int = 1
    var altitudeMeters:Int = 1000
    var timeString:String = "10:00 AM"
    var category:StopCategory = .permit
    var notes:String = ""
    
    
    /// Naye stop ko trip me add, local database me save, aur Firebase Cloud par upload karta hai:
    /// 1. `ItineraryStop` ka naya object banata hai.
    /// 2. Trip ke `stops` array me append karta hai.
    /// 3. SwiftData `modelContext` me save karta hai.
    /// 4. Firebase par auto-upload karta hai taaki sabhi members ko naya checkpoint mil jaye.
    /// 5. `onSuccess` callback trigger karta hai taaki View dismiss ho sake.
    func saveStop(to trip: Trip, modelContext: ModelContext, onSuccess: () -> Void) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanLocation = locationName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let newStop = ItineraryStop(
            dayNumber: dayNumber,
            title: cleanTitle.isEmpty ? "Stop Point" : cleanTitle,
            locationName: cleanLocation.isEmpty ? "Roadside" : cleanLocation,
            latitude: 27.5,
            longitude: 88.5,
            altitudeMeters: altitudeMeters,
            timeString: timeString,
            notes: notes,
            category: category
        )
        
        trip.stops.append(newStop)
        
        do {
            try modelContext.save()
            
//             Firebase Cloud par automatically upload kar do
            Task {
                try? await FirebaseSyncService.shared.uploadTripToFirebase(trip: trip)
            }
            
            onSuccess()
        } catch {
            print("Failed to save stop: \(error.localizedDescription)")
        }
    }
}
