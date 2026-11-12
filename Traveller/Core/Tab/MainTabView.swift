//
//  MainTabView.swift
//  Traveller
//
//  Created by Sahil Prasad on 12/11/26.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        if #available(iOS 18.0, *) {
            TabView{
                
                Tab {
                    TripVaultView()
                } label: {
                    Image(systemName: "suitcase.fill")
                    Text("Trips")
                }
                Tab{
                    SettingsView()
                }label:{
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                
                
                
                
                
            }
        } else {
            // Fallback on earlier versions
        }

        }
    }


#Preview {
    MainTabView()
}
