//
//  LoginViewModel.swift
//  Traveller
//
//  Created by Sahil Prasad on 10/11/26.
//

import Foundation
import Combine

class LoginViewModel:ObservableObject{
    static let shared = LoginViewModel()
    @Published var email = ""
    @Published var password = ""
    
    func signIn()async throws{
        try await AuthService.shared.login(email: email, password: password)
        
    }
}
