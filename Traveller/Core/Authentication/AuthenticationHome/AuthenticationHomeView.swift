//
//  AuthenticationHomeView.swift
//  Traveller
//
//  Created by Sahil Prasad on 10/11/26.
//

import SwiftUI

struct AuthenticationHomeView: View {
    // MARK: - View State
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case email, password
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    
                    // MARK: - Header
                    headerSection
                    
                    // MARK: - Input Fields
                    inputFieldsSection
                    
                    // MARK: - Sign In Button
                    signInButton
                    
                    // MARK: - Divider
                    dividerSection
                    
                    // MARK: - Google Sign-In Button
                    googleSignInButton
                    
                    Spacer(minLength: 24)
                    
                    // MARK: - Navigate to Sign Up View
                    footerSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .onTapGesture {
                focusedField = nil
            }
        }
    }
}

// MARK: - Subviews
extension AuthenticationHomeView {
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "airplane.departure")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.bottom, 4)
            
            Text("Welcome Back")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text("Sign in to access your trips, itineraries, and saved places.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }
    
    private var inputFieldsSection: some View {
        VStack(spacing: 16) {
            // Email Field
            HStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .foregroundStyle(focusedField == .email ? Color.accentColor : .secondary)
                    .frame(width: 20)
                
                TextField("Email Address", text: $email)
                    .keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .password
                    }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(focusedField == .email ? Color.accentColor : Color.clear, lineWidth: 1.5)
            )
            
            // Password Field
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(focusedField == .password ? Color.accentColor : .secondary)
                        .frame(width: 20)
                    
                    Group {
                        if isPasswordVisible {
                            TextField("Password", text: $password)
                                .textContentType(.password)
                        } else {
                            SecureField("Password", text: $password)
                                .textContentType(.password)
                        }
                    }
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .password)
                    .submitLabel(.done)
                    .onSubmit {
                        focusedField = nil
                    }
                    
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(focusedField == .password ? Color.accentColor : Color.clear, lineWidth: 1.5)
                )
                
                // You can also swap this Button for a NavigationLink if you have a ForgotPasswordView
                Button {
                    // Handle Forgot Password
                } label: {
                    Text("Forgot Password?")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
    
    private var signInButton: some View {
        Button {
            focusedField = nil
            // Handle Sign In Action
        } label: {
            Text("Sign In")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.accentColor.opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .disabled(email.isEmpty || password.isEmpty)
        .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
    }
    
    private var dividerSection: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 1)
            
            Text("OR")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 1)
        }
    }
    
    private var googleSignInButton: some View {
        Button {
            focusedField = nil
            // Handle Google Sign-In Action
        } label: {
            HStack(spacing: 12) {
                Text("G")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .yellow, .green, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 24, height: 24)
                
                Text("Continue with Google")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(.separator), lineWidth: 1)
            )
        }
    }
    
    private var footerSection: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            NavigationLink {
                NameView()
            } label: {
                Text("Sign Up")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.accentColor)
            }
        }
    }
}

#Preview {
    AuthenticationHomeView()
}

