//
//  SettingsView.swift
//  Traveller
//
//  Created by Sahil Prasad on 12/11/26.
//

import SwiftUI

struct SettingsView: View {
    
    // Pass your real user & action handlers from your ViewModel when ready
    @State private var viewModel = SettingsViewModel()
    var user: User? = nil
    
    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var notificationsEnabled = true
    @State private var autoCloudSync = true
    
    private var currentUser: User? {
        user ?? viewModel.currentUser
    }
    
    // Fallback preview/placeholder data when `currentUser` is nil
    private var displayName: String {
        currentUser?.name.isEmpty == false ? currentUser!.name : "Sahil Prasad"
    }
    
    private var displayUsername: String {
        let raw = currentUser?.username ?? "sahilprasad"
        return raw.hasPrefix("@") ? raw : "@\(raw)"
    }
    
    private var displayEmail: String {
        currentUser?.email?.isEmpty == false ? currentUser!.email! : "sahil@traveller.app"
    }
    
    private var displayBio: String {
        currentUser?.bio?.isEmpty == false ? currentUser!.bio! : "Explorer & Expedition Planner"
    }
    
    private var initials: String {
        let parts = displayName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? "T"
        let last = parts.dropFirst().first?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.03, green: 0.04, blue: 0.06)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // 1. Main User Profile Card
                        profileHeaderCard
                        
                        // 2. Account Details Section
                        accountDetailsSection
                        
                        // 3. Preferences & App Info
                        preferencesSection
                        
                        // 4. Sign Out & Delete Account
                        dangerZoneSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .task {
                await viewModel.loadCurrentUser()
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    viewModel.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out of \(displayEmail)?")
            }
            .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete Permanently", role: .destructive) {
                    Task{
                        do{
                            try await viewModel.deleteAccount()
                        }
                        catch{
                            print("Error while deleting account")
                        }
                        
                    }
                    
                }
            } message: {
                Text("This will permanently delete your account, profile details, and synced expedition data. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Profile Header Card
    
    private var profileHeaderCard: some View {
        HStack(spacing: 16) {
            avatarView
            
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                
                Text(displayUsername)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.cyan)
                
                HStack(spacing: 6) {
                    Image(systemName: "envelope.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(displayEmail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.top, 2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(red: 0.07, green: 0.09, blue: 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var avatarView: some View {
        if let urlString = currentUser?.profileImageUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    initialsAvatar
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.cyan.opacity(0.5), lineWidth: 2))
        } else {
            initialsAvatar
        }
    }
    
    private var initialsAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.cyan.opacity(0.18))
                .frame(width: 64, height: 64)
            Text(initials)
                .font(.title2.bold())
                .foregroundStyle(Color.cyan)
        }
        .overlay(Circle().stroke(Color.cyan.opacity(0.45), lineWidth: 1.5))
    }
    
    // MARK: - Account Details Section
    
    private var accountDetailsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("ACCOUNT DETAILS")
            
            VStack(spacing: 0) {
                detailRow(icon: "person.fill", title: "Full Name", value: displayName)
                rowDivider
                detailRow(icon: "at", title: "Username", value: displayUsername)
                rowDivider
                detailRow(icon: "envelope.fill", title: "Primary Email", value: displayEmail)
                rowDivider
                detailRow(icon: "text.quote", title: "Bio", value: displayBio)
                if let uid = currentUser?.id {
                    rowDivider
                    detailRow(icon: "number", title: "User ID", value: uid)
                }
            }
            .background(Color(red: 0.07, green: 0.09, blue: 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Preferences & App Info Section
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("PREFERENCES & APP")
            
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    iconBadge("bell.badge.fill", color: .cyan)
                    Text("Trip Notifications")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                    Spacer()
                    Toggle("", isOn: $notificationsEnabled)
                        .labelsHidden()
                        .tint(.cyan)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                
                rowDivider
                
                HStack(spacing: 12) {
                    iconBadge("icloud.fill", color: .emeraldGreen)
                    Text("Auto Cloud Sync")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                    Spacer()
                    Toggle("", isOn: $autoCloudSync)
                        .labelsHidden()
                        .tint(.cyan)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                
                rowDivider
                
                detailRow(icon: "info.circle.fill", title: "App Version", value: appVersion)
            }
            .background(Color(red: 0.07, green: 0.09, blue: 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Danger Zone (Sign Out & Delete Account)
    
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("ACCOUNT ACTIONS")
            
            VStack(spacing: 12) {
                Button {
                    showSignOutAlert = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.subheadline.weight(.semibold))
                        Text("Sign Out")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color(red: 0.07, green: 0.09, blue: 0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                
                Button {
                    showDeleteAccountAlert = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "trash.fill")
                            .font(.subheadline.weight(.semibold))
                        Text("Delete Account")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                    }
                    .foregroundStyle(Color.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.red.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.bold())
            .tracking(0.8)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 4)
    }
    
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            iconBadge(icon, color: .cyan)
            
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
            
            Spacer(minLength: 12)
            
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
    
    private func iconBadge(_ systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .frame(width: 28, height: 28)
            .background(color.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var rowDivider: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundStyle(Color.white.opacity(0.06))
            .padding(.leading, 54)
    }
}

#Preview {
    SettingsView(
        user: User(
            id: "uid_123456",
            username: "sahilprasad",
            profileImageUrl: nil,
            name: "Sahil Prasad",
            bio: "Explorer & Expedition Planner",
            email: "sahil@traveller.app"
        )
    )
}
