//
//  SignUpNameView.swift
//  Traveller
//
//  Created by Sahil Prasad on 10/11/26.
//

import SwiftUI

struct NameView: View {
    @EnvironmentObject var viewModel:RegistrationViewModel
    @FocusState private var isNameFocused:Bool
    private var isFormValid:Bool{
        !viewModel.name.isEmpty
    }
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack{
                stepProgression
                
                headerSection
                
                inputFieldSection
                
                nextButtonSection
                
                Spacer(minLength: 24)
                
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture {
            isNameFocused = false
        }
        .onAppear {
            isNameFocused = true
        }
        
    }
}

#Preview {
    NameView()
        .environmentObject(RegistrationViewModel())
}

extension NameView{
    private var stepProgression:some View{
        VStack(spacing:8){
            HStack{
                ForEach(0..<4,id:\.self){index in
                Capsule()
                        .fill(index <= 0 ? Color.accentColor : Color.accentColor.opacity(0.2))
                        .frame(height: 6)
                }
                
            }
            Text("Step 1 of 4")
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
                
                Image(systemName: "person.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.bottom, 4)
            
            Text("Enter your name")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text("Your name, which you would like to be displayed.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }
    
    private var inputFieldSection:some View{
        HStack(spacing: 12) {
            Image(systemName: "person.fill")
                .foregroundStyle(isNameFocused ? Color.accentColor : .secondary)
                .frame(width: 20)
            
            TextField("Your Name", text: $viewModel.name)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isNameFocused)
                .submitLabel(.next)
            
            if !viewModel.name.isEmpty {
                Button {
                    viewModel.name = ""
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
                .stroke(isNameFocused ? Color.accentColor : Color.clear, lineWidth: 1.5)
        )
    }
    
    private var nextButtonSection: some View {
        NavigationLink {
            EmailView()
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
}
