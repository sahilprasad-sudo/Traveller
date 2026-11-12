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
                if !trip.stops.isEmpty {
                    progressHeader
                }
                
                if trip.stops.isEmpty {
                    emptyStateView
                } else {
                    ForEach(viewModel.sortedStops(for: trip)) { stop in
                        stopRow(for: stop)
                    }
                    
                    clearAllButton
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
    
    // MARK: - Subviews
    
    private var progressHeader: some View {
        let completedCount = trip.stops.filter { $0.isCompleted }.count
        let progress = Double(completedCount) / Double(max(trip.stops.count, 1))
        
        return VStack(spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "figure.hiking")
                        .foregroundStyle(Color.cyan)
                    Text("\(completedCount) of \(trip.stops.count) Checkpoints Done")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                Spacer()
                
                Button(role: .destructive) {
                    showingClearConfirmation = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Clear")
                    }
                    .font(.caption.bold())
                    .foregroundStyle(.red.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.red.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan, Color.emeraldGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * progress))
                }
            }
            .frame(height: 6)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .background(Color(red: 0.05, green: 0.07, blue: 0.11).opacity(0.60))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }
    
    private var emptyStateView: some View {
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
    }
    
    private func stopRow(for stop: ItineraryStop) -> some View {
        let catColor = categoryColor(for: stop.category)
        
        return HStack(alignment: .top, spacing: 14) {
            // 1. Timeline Indicator & Connector Column
            VStack(spacing: 4) {
                Button {
                    viewModel.toggleStopCompletion(stop, in: trip, modelContext: modelContext)
                } label: {
                    Image(systemName: stop.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20))
                        .foregroundStyle(stop.isCompleted ? Color.emeraldGreen : .white.opacity(0.55))
                }
                
                Rectangle()
                    .fill(stop.isCompleted ? Color.emeraldGreen.opacity(0.45) : Color.white.opacity(0.18))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            
            // 2. Stop Details Card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Label("DAY \(stop.dayNumber)", systemImage: "flag.fill")
                        .font(.caption2.bold())
                        .foregroundStyle(Color.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.cyan.opacity(0.18))
                        .clipShape(Capsule())
                    
                    Label(stop.category.rawValue, systemImage: stop.category.iconName)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(catColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(catColor.opacity(0.16))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Label("\(stop.altitudeMeters)m", systemImage: "mountain.2.fill")
                        .font(.caption2.monospaced().bold())
                        .foregroundStyle(stop.altitudeMeters >= 3500 ? Color.orange : .white.opacity(0.75))
                }
                
                Text(stop.title)
                    .font(.headline)
                    .foregroundStyle(stop.isCompleted ? .white.opacity(0.5) : .white)
                    .strikethrough(stop.isCompleted)
                
                HStack(spacing: 12) {
                    Label(stop.locationName, systemImage: "mappin.and.ellipse")
                    Label(stop.timeString, systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
                
                if !stop.notes.isEmpty {
                    Text(stop.notes)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.78))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .background(Color(red: 0.05, green: 0.07, blue: 0.11).opacity(0.62))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
        .padding(.horizontal, 16)
    }
    
    private var clearAllButton: some View {
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
    
    private func categoryColor(for category: StopCategory) -> Color {
        switch category {
        case .travel: return .mint
        case .accomodation: return .indigo
        case .viewpoint: return .cyan
        case .food: return .orange
        case .permit: return .yellow
        }
    }
}

#Preview {
    ItineraryListView(trip: Trip())
        .modelContainer(for: Trip.self, inMemory: true)
}
