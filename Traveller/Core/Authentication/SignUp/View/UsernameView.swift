//
//  UsernameView.swift
//  Traveller
//
//  Created by Sahil Prasad on 10/11/26.
//

import SwiftUI

struct UsernameView: View {
    
    @EnvironmentObject var viewModel:RegistrationViewModel
    var body: some View {
        VStack(){
            
            Text("Enter your username")
            
            TextField(text: $viewModel.username) {
                Text("Your username here")
            }
            .textInputAutocapitalization(.never)
            .modifier(TextFieldModifier())
            .padding(.horizontal,10)
            
            
            NavigationLink {
                PasswordView()
            } label: {
                Text("Next")
            }
            .modifier(ButtonFieldModifier())
            .padding(.horizontal,10)
            
            Spacer()
        }
        .padding(.top,40)
    }
}

#Preview {
    UsernameView()
        .environmentObject(RegistrationViewModel())
}
