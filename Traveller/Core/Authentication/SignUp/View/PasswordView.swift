//
//  PasswordView.swift
//  Traveller
//
//  Created by Sahil Prasad on 10/11/26.
//

import SwiftUI

struct PasswordView: View {
   
    @EnvironmentObject var viewModel:RegistrationViewModel
    var body: some View {
        VStack(){
            
            Text("Enter your password")
            
            SecureField(text: $viewModel.password) {
                Text("Your name here")
            }
            .modifier(TextFieldModifier())
            .padding(.horizontal,10)
            
            
            Button {
                Task{
                    do{
                        try await viewModel.createUser()
                    }
                    catch{
                        print(error)
                    }
                    
                }
                
            } label: {
                Text("Complete Sign Up")
            }
            .modifier(ButtonFieldModifier())
            .padding(.horizontal,10)

            
            Spacer()
        }
        .padding(.top,40)
    }
}

#Preview {
    PasswordView()
        .environmentObject(RegistrationViewModel())
}
