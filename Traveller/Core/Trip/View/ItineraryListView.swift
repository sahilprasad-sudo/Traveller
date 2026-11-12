//
//  ItineraryListView.swift
//  Traveller
//
//  Created by Sahil Prasad on 12/11/26.
//

import SwiftUI
import SwiftData

struct ItineraryListView: View {
    @Bindable var trip: Trip
    
    /// SwiftData database context (checkpoint completion status database mein save karne ke liye)
    @Environment(\.modelContext) private var modelContext
    
    /// ViewModel jo sorting, stop completion aur cloud sync handle karta hai
    @State private var viewModel = ItineraryViewModel()
    @State private var showingClearConfirmation: Bool = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Top Header Bar with summary count & clear button
                if !trip.stops.isEmpty {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.badge.checkmark")
                                .foregroundStyle(Color.cyan)
                            Text("\(trip.stops.count) Checkpoints Scheduled")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(role: .destructive) {
                            showingClearConfirmation = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text("Clear Timetable")
                            }
                            .font(.caption.bold())
                            .foregroundStyle(.red.opacity(0.85))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.red.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                }
                
                if trip.stops.isEmpty {
                    // Empty state view
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary.opacity(0.6))
                        Text("No Itinerary Timetable")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("Your timetable is empty. Tap '+' to schedule new checkposts.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 60)
                    .padding(.horizontal, 24)
                } else {
                    // ViewModel se chronologically sorted stops fetch karke display karte hain
                    ForEach(viewModel.sortedStops(for: trip)) { stop in
                        HStack(alignment: .top, spacing: 14) {
                            
                            // 1. Timeline Indicator & Connector Column
                            VStack(spacing: 4) {
                                // Checkpoint complete/uncomplete toggle karne ka button
                                Button {
                                    // ViewModel method call hota hai jo status toggle karke Firebase par auto-sync karta hai
                                    viewModel.toggleStopCompletion(stop, in: trip, modelContext: modelContext)
                                } label: {
                                    // Agar complete ho gaya toh green checkmark, varna empty circle
                                    Image(systemName: stop.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 20))
                                        .foregroundStyle(stop.isCompleted ? Color.emeraldGreen : Color.secondary)
                                }
                                
                                // Vertical timeline line jo stops ko aapas mein visually connect karti hai
                                Rectangle()
                                    .fill(Color.white.opacity(0.12))
                                    .frame(width: 2)
                                    .frame(maxHeight: .infinity)
                            }
                            
                            // 2. Stop Details Card
                            VStack(alignment: .leading, spacing: 8) {
                                // Top Row: Day number aur Altitude meter
                                HStack {
                                    // Day Badge (e.g. "DAY 1")
                                    Label("DAY \(stop.dayNumber)", systemImage: "flag.fill")
                                        .font(.caption2.bold())
                                        .foregroundStyle(Color.cyan)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.cyan.opacity(0.15))
                                        .clipShape(Capsule())
                                    
                                    Spacer()
                                    
                                    // Altitude badge (e.g. "2900m")
                                    Label("\(stop.altitudeMeters)m", systemImage: "mountain.2")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                                
                                // Checkpoint Title: Complete hone par strikethrough (kata hua) text dikhta hai
                                Text(stop.title)
                                    .font(.headline)
                                    .foregroundStyle(stop.isCompleted ? .secondary : .primary)
                                    .strikethrough(stop.isCompleted)
                                
                                // Location name aur Scheduled time icons ke sath
                                HStack(spacing: 12) {
                                    Label(stop.locationName, systemImage: "mappin.and.ellipse")
                                    Label(stop.timeString, systemImage: "clock")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                
                                // Extra instructions ya alerts (agar present hon)
                                if !stop.notes.isEmpty {
                                    Text(stop.notes)
                                        .font(.caption)
                                        .foregroundStyle(.secondary.opacity(0.8))
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.white.opacity(0.03))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .padding(14)
                            .background(Color(red: 0.08, green: 0.10, blue: 0.14))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.06), lineWidth: 1))
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Bottom Clear Button
                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "trash.fill")
                                .font(.subheadline)
                            Text("Delete All Itinerary Timetable")
                                .font(.subheadline.bold())
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.red.opacity(0.8), Color.red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.red.opacity(0.25), radius: 6, x: 0, y: 3)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
            .padding(.vertical, 16)
        }
        .alert("Delete All Itinerary Timetable?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                withAnimation {
                    viewModel.clearAllStops(for: trip, modelContext: modelContext)
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } message: {
            Text("This will permanently remove all scheduled checkpoints and stops from this expedition's timetable.")
        }
    }
}

#Preview {
    ItineraryListView(trip: Trip())
        .modelContainer(for: Trip.self, inMemory: true)
}
