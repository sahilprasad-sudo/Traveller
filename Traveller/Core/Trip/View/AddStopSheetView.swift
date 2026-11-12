//
//  AddStopSheetView.swift
//  Traveller
//
//  Created by Sahil Prasad on 12/11/26.
//

import SwiftUI
import SwiftData

struct AddCheckpointSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    /// SwiftData database context (database mein naya stop save karne ke liye)
    @Environment(\.modelContext) private var modelContext
    
    /// Active Trip jisme naya stop judega
    var trip: Trip
    
    /// Form ke input states aur Firebase save logic ko manage karne wala ViewModel
    @State private var viewModel = AddCheckpostModel()
    
    // MARK: - Body View
    var body: some View {
        NavigationStack {
            Form {
                // Section 1: Checkpoint basic details
                Section("Checkpoint Details") {
                    // Checkpoint title input text field
                    TextField("Title (e.g. Lachen & Lachung Pass)", text: $viewModel.title)
                    
                    // Location name input text field
                    TextField("Location Name", text: $viewModel.locationName)
                    
                    // Category Picker (Transit, Stay, Viewpoint, Food, Permit)
                    Picker("Category", selection: $viewModel.category) {
                        ForEach(StopCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.iconName).tag(cat)
                        }
                    }
                }
                
                // Section 2: Timeline aur Altitude
                Section("Timeline & Altitude") {
                    // Day number stepper: 1 se 30 din tak choose karne ke liye
                    Stepper("Day \(viewModel.dayNumber)", value: $viewModel.dayNumber, in: 1...30)
                    
                    // Time input text field
                    TextField("Time (e.g. 11:30 AM)", text: $viewModel.timeString)
                    
                    // Altitude stepper: 100 meters ke step mein altitude badhane/ghatane ke liye
                    Stepper("Altitude: \(viewModel.altitudeMeters) m", value: $viewModel.altitudeMeters, step: 100)
                }
                
                // Section 3: Extra notes ya telemetry guidance
                Section("Notes & Offline Telemetry") {
                    // Multi-line vertical text field
                    TextField("Terrain, oxygen, permit notes...", text: $viewModel.notes, axis: .vertical)
                }
            }
            .navigationTitle("New Checkpoint")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel button: Form discard karke bina save kiye sheet band kar deta hai
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                // Save button: ViewModel ka saveStop method call karta hai
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Data validate hota hai, SwiftData mein save hota hai, Firebase par push hota hai, aur sheet close hoti hai
                        viewModel.saveStop(to: trip, modelContext: modelContext) {
                            dismiss()
                        }
                    }
                }
            }
        }
    }}

#Preview {
    AddCheckpointSheetView(trip: Trip())
}
