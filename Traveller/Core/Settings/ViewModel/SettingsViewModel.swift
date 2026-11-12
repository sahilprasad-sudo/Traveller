//
//  SettingsViewModel.swift
//  Traveller
//
//  Created by Sahil Prasad on 12/11/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import Observation

@Observable
final class SettingsViewModel{
    
    var currentUser:User? = AuthService.shared.currentUser
    private var cancellables = Set<AnyCancellable>()
    
    init() {
            AuthService.shared.$currentUser
                .receive(on: DispatchQueue.main)
                .sink { [weak self] user in
                    self?.currentUser = user
                }
                .store(in: &cancellables)
        }

    @MainActor
    func loadCurrentUser() async {
            if currentUser == nil {
                try? await AuthService.shared.loadUserData()
            }
        }
    @MainActor
    func signOut(){
        AuthService.shared.signOut()
        
    }
    
    @MainActor
    func updateUserProfile(updatedName: String? = nil,updatedUsername: String? = nil,updatedBio: String? = nil,updatedEmail: String? = nil) async throws {
        guard let uid = FirebaseAuth.Auth.auth().currentUser?.uid else { return }

           var data: [String: Any] = [:]

           if let name = updatedName, !name.isEmpty {
               data["name"] = name
           }
           if let username = updatedUsername, !username.isEmpty {
               data["username"] = username
           }
           if let bio = updatedBio {
               data["bio"] = bio
           }
           if let email = updatedEmail, !email.isEmpty {
               try await FirebaseAuth.Auth.auth().currentUser?.sendEmailVerification(beforeUpdatingEmail: email)
               data["email"] = email
           }
        
           guard !data.isEmpty else { return }

           try await Firestore.firestore()
               .collection("users")
               .document(uid)
               .updateData(data)

           // Refresh local currentUser from Firestore
           try await AuthService.shared.loadUserData()
       }
    
    func deleteAccount()async throws{
        guard let user = Auth.auth().currentUser else{
            return
        }
        let uid = user.uid
        try await Firestore.firestore().collection("users").document(uid).delete()
        try await user.delete()
        AuthService.shared.signOut()
    }
}
