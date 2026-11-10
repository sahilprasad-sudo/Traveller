//
//  EmailView.swift
//  Traveller
//
//  Created by Sahil Prasad on 10/11/26.
//

import SwiftUI

struct EmailView: View {
    @State private var email = ""
    @EnvironmentObject var viewModel:RegistrationViewModel
    var body: some View {
        VStack(){
            
            Text("Enter your email")
            
            TextField(text: $viewModel.email) {
                Text("Your email")
            }
            .textInputAutocapitalization(.never)
            .modifier(TextFieldModifier())
            .padding(.horizontal,10)
            
            
            NavigationLink {
                UsernameView()
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
    EmailView()
        .environmentObject(RegistrationViewModel())
}
