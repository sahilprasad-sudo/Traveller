//
//  HomeView.swift
//  Traveller
//
//  Created by Sahil Prasad on 10/11/26.
//

import SwiftUI

struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()
    var body: some View {
        Text("Welcome to Home")
        Button {
            viewModel.signOut()
        } label: {
            Text("Sign Out")
        }
        .modifier(ButtonFieldModifier())

    }
}

#Preview {
    HomeView()
}
