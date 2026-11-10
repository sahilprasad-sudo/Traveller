//
//  AuthenticationHomeModel.swift
//  Traveller
//
//  Created by Sahil Prasad on 11/11/26.
//

import Foundation
import Combine
import FirebaseAuth

class AuthenticationHomeModel:ObservableObject{
    static let shared = AuthenticationHomeView()
    
    @Published var email=""
    @Published var password = ""
    
    func resetPassword()async{
        do{
            try await AuthService.shared.resetPassword(email: email)
        }
        catch{
            print("Error encountered while resetting password-\(error.localizedDescription)")
        }
        
    }
    func signInWithGoogle()async{
        do{
            try await AuthService.shared.googleSignIn()
        }
        catch{
             print("Error encountered while trying to sign in with google:\(error.localizedDescription)")
        }
        
    }
    func signIn()async{
        do{
            try await AuthService.shared.login(email: email, password: password)
        }
        catch{
            print("Error Encountered while trying to sign In")
        }
    }
}
