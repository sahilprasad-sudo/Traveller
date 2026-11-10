//
//  HomeViewModel.swift
//  Traveller
//
//  Created by Sahil Prasad on 10/11/26.
//

import Foundation
import Combine

class HomeViewModel:ObservableObject{
    
    static let shared = HomeViewModel()
    
    func signOut(){
        AuthService.shared.signOut()
    }
}
