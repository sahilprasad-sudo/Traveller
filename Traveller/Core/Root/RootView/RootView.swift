//
//  RootView.swift
//  Traveller
//
//  Created by Sahil Prasad on 10/11/26.
//

import SwiftUI

struct RootView: View {
    @StateObject var viewModel = RootViewModel()
    @StateObject var registrationModel = RegistrationViewModel()
    var body: some View {
        Group{
            if (viewModel.userSession == nil){
                AuthenticationHomeView()
                    .environmentObject(registrationModel)
            }
            else if viewModel.currentUser != nil{
                HomeView()
            }
        }
    }
}

#Preview {
    RootView()
}
