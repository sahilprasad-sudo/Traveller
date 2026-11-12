//
//  RootView.swift
//  Traveller
//
//  Created by Sahil Prasad on 10/11/26.
//

import SwiftUI
import SwiftData

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
                TripVaultView()
                    .preferredColorScheme(.dark)
            }
                
        }
        .modelContainer(for: [Trip.self, ItineraryStop.self, Expense.self])
    }
}

#Preview {
    RootView()
}
