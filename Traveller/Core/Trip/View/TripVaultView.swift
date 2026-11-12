//
//  TripVaultView.swift
//  Traveller
//
//  Created by Sahil Prasad on 12/11/26.
//

import SwiftUI
import SwiftData

struct TripVaultView: View {
    
    /// SwiftData ka database context (data fetch aur save operations ke liye)
    @Environment(\.modelContext) private var modelContext
    
    /// SwiftData query: Database se saari trips fetch karti hai, sabse latest trip pehle aayegi
    @Query(sort: \Trip.creationDate, order: .reverse) private var trips: [Trip]
    
    /// Main dashboard ka ViewModel jo tab states aur Firebase sync manage karta hai
    @State private var viewModel = TripVaultViewModel()
    @State private var showingEditTripSheet: Bool = false
    @State private var editedTitle: String = ""
    @State private var editedSubtitle: String = ""
    
    /// Current active trip (query ki pehli trip)
    private var currentTrip: Trip? { trips.first }
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Scenic mountain background image with a dark gradient scrim so all text stays crisp and legible
                mountainBackground
                
                // Agar trip exist karti hai toh main dashboard dikhate hain
                if let trip = currentTrip {
                    VStack(spacing: 0) {
                        // 1. Trip Hero Header + Compact Cloud Sync Pill
                        tripHeroHeader(trip: trip)
                        
                        // 2. Tab Switcher (Timeline vs Expenses)
                        tabPicker
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                            .padding(.bottom, 8)
                        
                        // 3. Tab Pages
                        TabView(selection: $viewModel.selectedTab) {
                            // Tab 0: Itinerary Timeline List
                            ItineraryListView(trip: trip)
                                .tag(0)
                            
                            // Tab 1: Expenses & Debts Vault
                            ExpensesVaultView(trip: trip)
                                .tag(1)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never)) // Paging dots hide karta hai
                    }
                } else {
                    // Agar koi trip nahi hai toh empty state view dikhate hain
                    emptyStateView
                }
            }
            .navigationTitle("Expedition Vault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Top-left corner: Members pill button to view and add members
                ToolbarItem(placement: .topBarLeading) {
                    if let trip = currentTrip {
                        Button {
                            viewModel.showingMembersSheet = true
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "person.2.fill")
                                Text("\(trip.members.count)")
                                    .font(.caption.bold())
                            }
                            .foregroundStyle(Color.cyan)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Color.cyan.opacity(0.15))
                            .clipShape(Capsule())
                        }
                    }
                }
                
                // Top-right corner mein '+' button: Active tab ke hisaab se sahi sheet open karta hai
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.handlePlusButtonTap()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.cyan)
                    }
                }
            }
            // Members manage karne ki popup modal sheet
            .sheet(isPresented: $viewModel.showingMembersSheet) {
                if let trip = currentTrip {
                    ManageMembersSheetView(trip: trip)
                }
            }
            // Checkpoint add karne ki popup modal sheet
            .sheet(isPresented: $viewModel.showingAddStopSheet) {
                if let trip = currentTrip {
                    AddCheckpointSheetView(trip: trip)
                }
            }
            // Expense add karne ki popup modal sheet
            .sheet(isPresented: $viewModel.showingAddExpenseSheet) {
                if let trip = currentTrip {
                    AddExpensesSheetView(trip: trip)
                }
            }
            // Trip title aur subtitle edit karne ki modal sheet
            .sheet(isPresented: $showingEditTripSheet) {
                if let trip = currentTrip {
                    editTripSheet(for: trip)
                }
            }
            // Screen load hote hi agar koi data nahi hai toh demo data seed karta hai
            .onAppear {
                viewModel.seedInitialDataIfNeeded(trips: trips, modelContext: modelContext)
            }
        }
    }
    
    // MARK: - Subviews & UI Components
    
    /// Trip Hero Header: Shows destination title, subtitle, quick trip stats, and compact cloud sync pill
    private func tripHeroHeader(trip: Trip) -> some View {
        let completedStops = trip.stops.filter { $0.isCompleted }.count
        let maxAltitude = trip.stops.map(\.altitudeMeters).max() ?? 0
        
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(trip.title.isEmpty ? "Mountain Expedition" : trip.title)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        
                        Button {
                            editedTitle = trip.title
                            editedSubtitle = trip.subtitle
                            showingEditTripSheet = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.cyan.opacity(0.9))
                        }
                        .accessibilityLabel("Edit Trip Details")
                    }
                    
                    HStack(spacing: 5) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundStyle(Color.cyan)
                        Text(trip.subtitle.isEmpty ? "Scenic Route" : trip.subtitle)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Compact Cloud Sync Button Pill
                Button {
                    viewModel.syncWithFirebase(trip: trip, modelContext: modelContext)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: viewModel.isSyncing ? "arrow.triangle.2.circlepath.circle.fill" : "icloud.fill")
                            .font(.caption2)
                            .rotationEffect(.degrees(viewModel.isSyncing ? 360 : 0))
                            .animation(viewModel.isSyncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isSyncing)
                        Text(viewModel.isSyncing ? "Syncing" : "Sync")
                            .font(.caption2.bold())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.cyan.opacity(0.35), lineWidth: 1))
                    .foregroundStyle(Color.cyan)
                }
                .disabled(viewModel.isSyncing)
            }
            
            // Quick Trip Stats & Sync Status Strip
            HStack(spacing: 8) {
                Label("\(completedStops)/\(trip.stops.count) Stops", systemImage: "flag.checkered")
                    .font(.caption2)
                    .bold()
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.10), in: Capsule())
                
                if maxAltitude > 0 {
                    Label("\(maxAltitude)m Peak", systemImage: "mountain.2.fill")
                        .font(.caption2)
                        .bold()
                        .foregroundStyle(Color.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.cyan.opacity(0.15), in: Capsule())
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(viewModel.isSyncing ? Color.orange : Color.emeraldGreen)
                        .frame(width: 6, height: 6)
                    Text(viewModel.syncStatusMessage)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .background(Color(red: 0.04, green: 0.06, blue: 0.10).opacity(0.45))
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.white.opacity(0.10)), alignment: .bottom)
    }
    
    /// Full-screen scenic mountain background with dark atmospheric scrim for text readability
    private var mountainBackground: some View {
        Color.clear
            .overlay {
                Image("MountainBackground")
                    .resizable()
                    .scaledToFill()
            }
            .overlay {
                LinearGradient(
                    colors: [
                        Color(red: 0.03, green: 0.04, blue: 0.07).opacity(0.62),
                        Color(red: 0.03, green: 0.04, blue: 0.07).opacity(0.38),
                        Color(red: 0.03, green: 0.04, blue: 0.07).opacity(0.72)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipped()
            .ignoresSafeArea()
    }
    
    /// Custom Tab Selector: "Itinerary Timeline" aur "Expenses & Debts" ke beech toggle karne ke liye
    private var tabPicker: some View {
        HStack(spacing: 0) {
            // Tab 1 Button: Itinerary
            Button {
                viewModel.selectTab(0)
            } label: {
                HStack {
                    Image(systemName: "map.fill")
                    Text("Itinerary Timeline")
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(viewModel.selectedTab == 0 ? Color.cyan.opacity(0.2) : Color.clear)
                .foregroundStyle(viewModel.selectedTab == 0 ? Color.cyan : Color.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Tab 2 Button: Expenses
            Button {
                viewModel.selectTab(1)
            } label: {
                HStack {
                    Image(systemName: "indianrupeesign.circle.fill")
                    Text("Expenses & Debts")
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(viewModel.selectedTab == 1 ? Color.cyan.opacity(0.2) : Color.clear)
                .foregroundStyle(viewModel.selectedTab == 1 ? Color.cyan : Color.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .background(Color(red: 0.04, green: 0.06, blue: 0.10).opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }
    
    /// Empty State View: Jab koi trip exist nahi karti tab create button dikhata hai
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Expedition Active")
                .font(.headline)
            Button("Create Expedition") {
                viewModel.seedInitialDataIfNeeded(trips: trips, modelContext: modelContext)
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
        }
    }
    
    /// Trip Title & Subtitle Editor Sheet
    private func editTripSheet(for trip: Trip) -> some View {
        NavigationStack {
            Form {
                Section("Expedition Details") {
                    TextField("Trip Title (e.g. North Sikkim)", text: $editedTitle)
                    TextField("Location / Subtitle (e.g. Gangtok)", text: $editedSubtitle)
                }
            }
            .navigationTitle("Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingEditTripSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedTitle = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedSubtitle = editedSubtitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedTitle.isEmpty {
                            trip.title = trimmedTitle
                        }
                        trip.subtitle = trimmedSubtitle
                        try? modelContext.save()
                        viewModel.syncWithFirebase(trip: trip, modelContext: modelContext)
                        showingEditTripSheet = false
                    }
                    .fontWeight(.semibold)
                    .disabled(editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    TripVaultView()
}
