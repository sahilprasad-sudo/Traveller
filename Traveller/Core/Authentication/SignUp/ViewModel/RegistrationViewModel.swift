//
//  RegistrationViewModel.swift
//  Traveller
//
//  Created by Sahil Prasad on 10/11/26.
//

import Foundation
import Combine
import FirebaseAuth

class RegistrationViewModel:ObservableObject{
    
    static let shared = RegistrationViewModel()
    
    @Published var name = ""
    @Published var username = ""
    @Published var email = ""
    @Published var password = ""
    
    @MainActor
    func createUser() async throws{
        try await AuthService.shared.createUser(email: email, password: password, username: username, name: name)
        email=""
        password=""
        username=""
        name=""
    }
}
