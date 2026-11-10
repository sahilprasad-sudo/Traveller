//
//  AuthService.swift
//  Traveller
//
//  Created by Sahil Prasad on 10/11/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

class AuthService{
    
    static let shared = AuthService()
    
    @Published var userSession : FirebaseAuth.User?
    @Published var currentUser:User?
    
    init(){
        Task{
            try? await loadUserData()
        }
        
    }
    
    @MainActor
    func login(email:String,password:String) async throws{
        do{
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            try await loadUserData()
            self.userSession = result.user
        }
        catch{
            print("Error encountered while trying to log in -\(error.localizedDescription)")
            throw error
        }
    }
    @MainActor
    func createUser(email:String,password:String,username:String,name:String) async throws{
        do{
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.userSession = result.user
            try await uploadUserData(uid: result.user.uid, email: email, username: username, name: name)
        }
        catch{
            print("Error encountered while trying to create user -\(error.localizedDescription)")
            throw error
        }
    }
    @MainActor
    func uploadUserData(uid:String,email:String,username:String,name:String) async throws{
        let user = User(id:uid,username:username,name:name, email:email)
        self.currentUser = user
        
        guard let encodedUser = try? Firestore.Encoder().encode(user)else{
            return
        }
        do{
            try await Firestore.firestore().collection("users").document(user.id).setData(encodedUser)
            print("User Successfully saved in Database")
        }
        catch{
            print("Error encountered while trying to upload user data to server -\(error.localizedDescription)")
            throw error
        }
    }
    @MainActor
    func loadUserData()async throws{
        self.userSession = Auth.auth().currentUser
        guard let currentUid = userSession?.uid else{
            return
        }
        let snapshot = try await Firestore.firestore().collection("users").document(currentUid).getDocument()
        self.currentUser = try? snapshot.data(as: User.self)
    }
    @MainActor
    func signOut() {
            try? Auth.auth().signOut()
            self.userSession = nil
            self.currentUser = nil
        }
}
