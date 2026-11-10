//
//  PasswordView.swift
//  Traveller
//
//  Created by Sahil Prasad on 10/11/26.
//

import SwiftUI

struct PasswordView: View {
   
    @EnvironmentObject var viewModel:RegistrationViewModel
    @FocusState private var isPasswordFocused:Bool
    @State private var isLoading: Bool = false
    private var isFormValid:Bool{
        !viewModel.password.isEmpty
    }
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                
                // MARK: - Step Progress
                stepProgression
                
                // MARK: - Header
                headerSection
                
                // MARK: - Input Field
                inputFieldSection
                
                // MARK: - Complete Sign Up Button
                completeSignUpButtonSection
                
                Spacer(minLength: 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            isPasswordFocused = false
        }
        .onAppear {
            isPasswordFocused = true
        }
    }
}

#Preview {
    PasswordView()
        .environmentObject(RegistrationViewModel())
}
extension PasswordView{
    private var stepProgression:some View{
        VStack(spacing:8){
            HStack{
                ForEach(0..<4,id:\.self){index in
                Capsule()
                        .fill(index <= 3 ? Color.accentColor : Color.accentColor.opacity(0.2))
                        .frame(height: 6)
                }
                
            }
            Text("Step 3 of 4")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
    
    private var headerSection:some View{
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 76, height: 76)
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.bottom, 4)
            
            Text("Enter your Password")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text("Please don't share your password,not even to your loved ones ;)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }
    
    private var inputFieldSection:some View{
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundStyle(isPasswordFocused ? Color.accentColor : .secondary)
                .frame(width: 20)
            
            SecureField("Password", text: $viewModel.password)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isPasswordFocused)
                .submitLabel(.next)
            
            if !viewModel.password.isEmpty {
                Button {
                    viewModel.password = ""
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
                .stroke(isPasswordFocused ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
    }
    
    private var nextButtonSection: some View {
        NavigationLink {
            UsernameView()
        } label: {
            HStack(spacing: 8) {
                Text("Continue")
                    .font(.headline)
                
                Image(systemName: "arrow.right")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.accentColor.opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .disabled(!isFormValid)
        .opacity(isFormValid ? 1.0 : 0.6)
    }
    private var completeSignUpButtonSection: some View {
        Button {
            isPasswordFocused = false
            isLoading = true
            Task {
                do {
                    try await viewModel.createUser()
                } catch {
                    print(error)
                }
                isLoading = false
            }
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Complete Sign Up")
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

