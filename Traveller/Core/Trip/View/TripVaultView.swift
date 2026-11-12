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
    
    /// Current active trip (query ki pehli trip)
    private var currentTrip: Trip? { trips.first }
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background dark theme color (Pure screen par dark color fill karta hai)
                Color(red: 0.03, green: 0.04, blue: 0.06).ignoresSafeArea()
                
                // Agar trip exist karti hai toh main dashboard dikhate hain
                if let trip = currentTrip {
                    VStack(spacing: 0) {
                        // 1. Top Firebase Cloud Sync Bar
                        cloudSyncBar(trip: trip)
                        
                        // 2. Tab Switcher (Timeline vs Expenses)
                        tabPicker
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
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
            // Screen load hote hi agar koi data nahi hai toh demo data seed karta hai
            .onAppear {
                viewModel.seedInitialDataIfNeeded(trips: trips, modelContext: modelContext)
            }
        }
    }
    
    // MARK: - Subviews & UI Components
    
    /// Top Cloud Sync Bar:
    /// Firebase sync status batata hai aur manual "Sync Now" button provide karta hai
    private func cloudSyncBar(trip: Trip) -> some View {
        HStack(spacing: 12) {
            // Cloud status indicator: Syncing hone par icon ghumta hai
            HStack(spacing: 6) {
                Image(systemName: viewModel.isSyncing ? "arrow.triangle.2.circlepath.circle.fill" : "cloud.fill")
                    .font(.caption)
                    .foregroundStyle(Color.cyan)
                    .rotationEffect(.degrees(viewModel.isSyncing ? 360 : 0))
                    .animation(viewModel.isSyncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isSyncing)
                
                // Status message jaise "ALL DEVICES IN SYNC" ya "SYNCING..."
                Text(viewModel.syncStatusMessage.uppercased())
                    .font(.caption2.bold())
                    .tracking(0.6)
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            // "Sync Now" button: User manual sync trigger kar sakta hai
            Button {
                
                viewModel.syncWithFirebase(trip: trip, modelContext: modelContext)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise.icloud.fill")
                        .font(.caption2)
                    Text(viewModel.isSyncing ? "Syncing..." : "Sync Now")
                        .font(.caption2.weight(.medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.cyan.opacity(0.18))
                .clipShape(Capsule())
                .foregroundStyle(Color.cyan)
            }
            .disabled(viewModel.isSyncing) // Syncing ke time double tap disable karta hai
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(red: 0.07, green: 0.09, blue: 0.12))
        .overlay(Rectangle().frame(height: 1).foregroundStyle(Color.white.opacity(0.08)), alignment: .bottom)
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
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
}

#Preview {
    TripVaultView()
}
