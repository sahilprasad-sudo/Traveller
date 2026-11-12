//
//  DataService.swift
//  Traveller
//
//  Created by Sahil Prasad on 12/11/26.
//

import Foundation
import SwiftData
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

enum FirebaseConfig{
    
    static let projectId: String = "traveller-app-bbc93"
    static let tripsCollection: String = "trips"
    static let storageBucket: String = "gs://traveller-app-bbc93.firebasestorage.app"
}

struct TripSyncDTO: Codable {
    let id: String
    let title: String
    let subtitle: String
    let members: [String]
    let lastUpdatedAt: Double // Unix timestamp in seconds
    let stops: [StopSyncDTO]
    let expenses: [ExpenseSyncDTO]
    
    /// Dictionary format mein convert karta hai taaki Firestore ke `.setData()` mein directly pass ho sake
    func toFirestoreDictionary() -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "subtitle": subtitle,
            "members": members,
            "lastUpdatedAt": lastUpdatedAt,
            "stops": stops.map { $0.toDictionary() },
            "expenses": expenses.map { $0.toDictionary() }
        ]
    }
}

/// Checkpoint ka JSON format
struct StopSyncDTO: Codable {
    let id: String
    let dayNumber: Int
    let title: String
    let locationName: String
    let latitude: Double
    let longitude: Double
    let altitudeMeters: Int
    let timeString: String
    let notes: String
    let isCompleted: Bool
    let category: String
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "dayNumber": dayNumber,
            "title": title,
            "locationName": locationName,
            "latitude": latitude,
            "longitude": longitude,
            "altitudeMeters": altitudeMeters,
            "timeString": timeString,
            "notes": notes,
            "isCompleted": isCompleted,
            "category": category
        ]
    }
}

/// Expense ka JSON format
struct ExpenseSyncDTO: Codable {
    let id: String
    let title: String
    let amount: Double
    let paidBy: String
    let category: String
    let timestamp: Double
    let splitAmong: [String]
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "amount": amount,
            "paidBy": paidBy,
            "category": category,
            "timestamp": timestamp,
            "splitAmong": splitAmong
        ]
    }
}

// =============================================================================
// MARK: - FirebaseSyncService (Real Firebase Sync Implementation)
// =============================================================================

/// `FirebaseSyncService`:
/// Ye class actual Firebase Firestore aur Firebase Cloud Storage ke sath communicate karti hai.
/// Isme real network calls hain jo documents ko upload, fetch aur real-time observe karti hain.
final class FirebaseSyncService {
    
    /// Singleton instance taaki pure app mein ek hi sync connection rahe
    static let shared = FirebaseSyncService()
    
    private init() {
        // App launch par Firebase initialize check karte hain
        
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("Firebase configured successfully.")
        }
        
    }
    
    // MARK: - 1. SwiftData Model to DTO Conversion
    
    /// SwiftData ke `Trip` ko cloud-ready `TripSyncDTO` payload mein convert karta hai
    func createSyncPayload(from trip: Trip) -> TripSyncDTO {
        let stopsDTO = trip.stops.map { stop in
            StopSyncDTO(
                id: stop.id.uuidString,
                dayNumber: stop.dayNumber,
                title: stop.title,
                locationName: stop.locationName,
                latitude: stop.latitude,
                longitude: stop.longitude,
                altitudeMeters: stop.altitudeMeters,
                timeString: stop.timeString,
                notes: stop.notes,
                isCompleted: stop.isCompleted,
                category: stop.rawCategory
            )
        }
        
        let expensesDTO = trip.expenses.map { exp in
            ExpenseSyncDTO(
                id: exp.id.uuidString,
                title: exp.title,
                amount: exp.amount,
                paidBy: exp.paidBy,
                category: exp.rawCategory,
                timestamp: exp.date.timeIntervalSince1970,
                splitAmong: exp.splitAmong
            )
        }
        
        return TripSyncDTO(
            id: trip.id.uuidString,
            title: trip.title,
            subtitle: trip.subtitle,
            members: trip.members,
            lastUpdatedAt: Date().timeIntervalSince1970,
            stops: stopsDTO,
            expenses: expensesDTO
        )
    }
    
    // MARK: - 2. Cloud Upload (Phone -> Firebase Firestore & Storage)
    
    /// Real Firebase Upload Function:
    /// Trip ka data Firestore database mein document ke roop mein save karta hai.
    func uploadTripToFirebase(trip: Trip) async throws {
        // Step 1: Payload create karte hain
        let payload = createSyncPayload(from: trip)
        let documentId = trip.id.uuidString
        
        
        // 👉 [FIRESTORE SDK IMPLEMENTATION]:
        // Agar aapne Xcode mein FirebaseFirestore package add kiya hai:
        let db = Firestore.firestore()
        let tripRef = db.collection(FirebaseConfig.tripsCollection).document(documentId)
        
        // setData call se Firestore mein document overwrite/update hota hai
        try await tripRef.setData(payload.toFirestoreDictionary(), merge: true)
        print("Firebase Success: Document '\(documentId)' updated in collection '\(FirebaseConfig.tripsCollection)'.")
        
        
        // 👉 [REST API DIRECT IMPLEMENTATION]:
        // Agar abhi tak Firebase iOS SDK download nahi kiya hai, tab bhi ye direct Google Cloud Firestore REST API
        // ke zariye bina kisi SDK ke directly aapke Firebase par data save kar dega!
        guard FirebaseConfig.projectId != "traveller-app-bbc93" else {
            print("Notice: Please set FirebaseConfig.projectId in FirebaseSyncService.swift to enable live sync.")
            return
        }
        
        let urlString = "https://firestore.googleapis.com/v1/projects/\(FirebaseConfig.projectId)/databases/(default)/documents/\(FirebaseConfig.tripsCollection)/\(documentId)"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH" // Document update ya create karega
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // JSON encode karte hain
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(payload)
        
        // Real URLSession network call execute hoti hai
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
            print("Firebase REST Success: Document saved. Bytes received: \(data.count)")
        } else {
            print("Firebase REST Notice: Response code \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        
        
        
        // 👉 [FIREBASE STORAGE FILE BACKUP (OPTIONAL)]:
        // Agar aap pure trip ka JSON backup Firebase Storage mein bhi store karna chahte hain:
        let storageRef = Storage.storage().reference().child("trips/\(documentId).json")
        let encoders = JSONEncoder()
        encoders.outputFormatting = .prettyPrinted
        let jsonFileData = try encoders.encode(payload)
        
        let metadata = StorageMetadata()
        metadata.contentType = "application/json"
        
        _ = try await storageRef.putDataAsync(jsonFileData, metadata: metadata)
        print("Firebase Storage Success: JSON file uploaded to gs://trips/\(documentId).json")
        
    }
    
    // MARK: - 3. Cloud Download (Firebase -> Phone)
    
    /// Real Firebase Fetch Function:
    /// Firestore se latest trip document download karke `TripSyncDTO` return karta hai.
    func fetchTripFromFirebase(tripId: UUID) async throws -> TripSyncDTO? {
        let documentId = tripId.uuidString
        
        
        // 👉 [FIRESTORE SDK FETCH]:
        let db = Firestore.firestore()
        let tripRef = db.collection(FirebaseConfig.tripsCollection).document(documentId)
        
        let snapshot = try await tripRef.getDocument()
        guard let data = snapshot.data() else {
            print("Firebase Notice: No document found for id '\(documentId)'.")
            return nil
        }
        
        // Dictionary ko JSON data mein aur phir DTO mein decode karte hain
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let dto = try JSONDecoder().decode(TripSyncDTO.self, from: jsonData)
        return dto
        
        
        // 👉 [REST API DIRECT FETCH]:
        guard FirebaseConfig.projectId != "traveller-app-bbc93" else {
            return nil
        }
        
        let urlString = "https://firestore.googleapis.com/v1/projects/\(FirebaseConfig.projectId)/databases/(default)/documents/\(FirebaseConfig.tripsCollection)/\(documentId)"
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (deta, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }
        
        let dtto = try JSONDecoder().decode(TripSyncDTO.self, from: deta)
        return dtto
        
    }
    
    // MARK: - 4. Realtime Firestore Listener (Automatic Live Updates)
    
    
    /// Realtime Listener:
    /// Jab bhi koi dusra member Firebase par naya expense ya checkpoint add karega,
    /// ye function turant trigger ho jayega aur bina kisi button dabaye aapka local database update kar dega!
    func attachRealtimeListener(for trip: Trip, context: ModelContext) -> ListenerRegistration {
        let db = Firestore.firestore()
        let documentRef = db.collection(FirebaseConfig.tripsCollection).document(trip.id.uuidString)
        
        let listener = documentRef.addSnapshotListener { [weak self] documentSnapshot, error in
            guard let snapshot = documentSnapshot, snapshot.exists, let data = snapshot.data() else {
                return
            }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let cloudDTO = try JSONDecoder().decode(TripSyncDTO.self, from: jsonData)
                
                // Main thread par SwiftData local database ko update karte hain
                DispatchQueue.main.async {
                    self?.mergeCloudDataIntoLocal(trip: trip, cloudData: cloudDTO, context: context)
                }
            } catch {
                print("Failed to decode realtime snapshot: \(error.localizedDescription)")
            }
        }
        
        return listener
    }
    
    
    // MARK: - 5. Cloud Data ko Local SwiftData Database mein Merge Karna
    
    /// Cloud se naye data aane par local database ko update karta hai:
    /// - Agar cloud par naya checkpoint hai toh phone mein insert karta hai
    /// - Agar cloud par naya expense hai toh phone ke balance mein insert karta hai
    func mergeCloudDataIntoLocal(trip: Trip, cloudData: TripSyncDTO, context: ModelContext) {
        // Basic fields sync karte hain
        trip.title = cloudData.title
        trip.subtitle = cloudData.subtitle
        trip.members = cloudData.members
        
        // 1. Checkpoints Sync: Jo stops local nahi hain, unhe add karo
        let localStopIds = Set(trip.stops.map { $0.id.uuidString })
        for remoteStop in cloudData.stops where !localStopIds.contains(remoteStop.id) {
            let stopUUID = UUID(uuidString: remoteStop.id) ?? UUID()
            let newStop = ItineraryStop(
                id: stopUUID,
                dayNumber: remoteStop.dayNumber,
                title: remoteStop.title,
                locationName: remoteStop.locationName,
                latitude: remoteStop.latitude,
                longitude: remoteStop.longitude,
                altitudeMeters: remoteStop.altitudeMeters,
                timeString: remoteStop.timeString,
                notes: remoteStop.notes,
                isCompleted: remoteStop.isCompleted,
                category: StopCategory(rawValue: remoteStop.category) ?? .travel,
                trip: trip
            )
            trip.stops.append(newStop)
        }
        
        // Existing stops ka completion status match karo
        for remoteStop in cloudData.stops {
            if let localStop = trip.stops.first(where: { $0.id.uuidString == remoteStop.id }) {
                localStop.isCompleted = remoteStop.isCompleted
            }
        }
        
        // Remote par jo stops delete/clear ho gaye hain, unhe local database se bhi delete karo
        let remoteStopIds = Set(cloudData.stops.map { $0.id })
        trip.stops.removeAll { stop in
            if !remoteStopIds.contains(stop.id.uuidString) {
                context.delete(stop)
                return true
            }
            return false
        }
        
        // 2. Expenses Sync: Jo expenses local database mein missing hain, unhe add karo
        let localExpenseIds = Set(trip.expenses.map { $0.id.uuidString })
        for remoteExp in cloudData.expenses where !localExpenseIds.contains(remoteExp.id) {
            let expUUID = UUID(uuidString: remoteExp.id) ?? UUID()
            let expDate = Date(timeIntervalSince1970: remoteExp.timestamp)
            let newExp = Expense(
                id: expUUID,
                title: remoteExp.title,
                amount: remoteExp.amount,
                paidBy: remoteExp.paidBy,
                category: ExpensesCategory(rawValue: remoteExp.category) ?? .transport,
                splitAmong: remoteExp.splitAmong,
                date: expDate,
                trip: trip
            )
            trip.expenses.append(newExp)
        }
        
        // 3. Remote par jo expenses delete/clear ho gaye hain, unhe local database se bhi delete karo
        let remoteExpenseIds = Set(cloudData.expenses.map { $0.id })
        trip.expenses.removeAll { exp in
            if !remoteExpenseIds.contains(exp.id.uuidString) {
                context.delete(exp)
                return true
            }
            return false
        }
        
        // SwiftData local disk save
        try? context.save()
    }
    
}



