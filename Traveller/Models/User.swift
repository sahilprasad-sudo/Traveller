//
//  User.swift
//  Traveller
//
//  Created by Sahil Prasad on 10/11/26.
//

import Foundation
import FirebaseAuth

struct User:Codable,Identifiable,Hashable{
    let id:String
    var username:String
    var profileImageUrl:String?
    var name:String
    var bio:String?
    var email:String?
    
    var isCurrentUser:Bool{
        guard let currentUid = Auth.auth().currentUser?.uid else{
            return false
        }
        return currentUid == id
    }
}
