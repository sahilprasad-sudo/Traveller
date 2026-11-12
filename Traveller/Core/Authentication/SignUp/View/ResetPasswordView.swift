//
//  ResetPasswordView.swift
//  Traveller
//
//  Created by Sahil Prasad on 11/11/26.
//

import SwiftUI

struct ResetPasswordView: View {
    @EnvironmentObject var viewModel:RegistrationViewModel
    @State private var activeAlert: AlertItem?
    @FocusState private var isEmailFocused: Bool
    @State private var isLoading: Bool = false
    private var isFormValid: Bool {
        !viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                
                // MARK: - Step Progress
                
                
                // MARK: - Header
                headerSection
                
                // MARK: - Input Field
                inputFieldSection
                
                // MARK: - Next Button
                resetPasswordButton
                
                Spacer(minLength: 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            isEmailFocused = false
        }
        .onAppear {
            isEmailFocused = true
        }
        .customAlert(item: $activeAlert)
    }
        
}

#Preview {
    ResetPasswordView()
        .environmentObject(RegistrationViewModel())
    
}
extension ResetPasswordView {
    
    
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 76, height: 76)
                
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.bottom, 4)
            
            Text("Enter your email")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text("Please ennter the same email which you used during the time of registering")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }
    
    private var inputFieldSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "envelope.fill")
                .foregroundStyle(isEmailFocused ? Color.accentColor : .secondary)
                .frame(width: 20)
            
            TextField("Email Address", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isEmailFocused)
                .submitLabel(.next)
            
            if !viewModel.email.isEmpty {
                Button {
                    viewModel.email = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isEmailFocused ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
    }
    
    
    private var resetPasswordButton: some View {
        Button {
            isEmailFocused = false
            isLoading = true
            Task {
                await viewModel.resetPassword()
                // Check if there was an error in viewModel
                if let error = viewModel.errorMessage {
                            activeAlert = AlertItem(
                                title: "Error",
                                message: error
                            )
                        } else {
                            activeAlert = AlertItem(
                                title: "Password Email Sent",
                                message: "Please check your registered email to reset your password."
                            )
                        }
                        
                isLoading = false
            }
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Send Reset Email")
                        .font(.headline)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                }
                
            }
            
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.accentColor.opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .disabled(!isFormValid || isLoading)
        .opacity(isFormValid && !isLoading ? 1.0 : 0.6)
    }
}

