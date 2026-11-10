//
//  SignUpNameView.swift
//  Traveller
//
//  Created by Sahil Prasad on 10/11/26.
//

import SwiftUI

struct NameView: View {
    @EnvironmentObject var viewModel:RegistrationViewModel
    var body: some View {
        NavigationStack{
            VStack(){
                
                Text("Enter your full name")
                
                TextField(text: $viewModel.name) {
                    Text("Your name here")
                }
                .modifier(TextFieldModifier())
                .padding(.horizontal,10)
                
                
                NavigationLink {
                    EmailView()
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
}

#Preview {
    NameView()
        .environmentObject(RegistrationViewModel())
}
