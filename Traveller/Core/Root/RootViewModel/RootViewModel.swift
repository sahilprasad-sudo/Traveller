//
//  RootViewModel.swift
//  Traveller
//
//  Created by Sahil Prasad on 10/11/26.
//

import Foundation
import Combine
import FirebaseAuth

class RootViewModel:ObservableObject{
    private let service = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var userSession:FirebaseAuth.User?
    @Published var currentUser:User?
    
    init(){
        setupSubscribers()
    }
    func setupSubscribers(){
        service.$userSession
            .receive(on: DispatchQueue.main)
            .sink{[weak self] userSession in
                self?.userSession = userSession
            }
            .store(in: &cancellables)
        
        service.$currentUser
            .receive(on: DispatchQueue.main)
            .sink{[weak self] currentUser in
                self?.currentUser = currentUser
            }
            .store(in: &cancellables)
    }
    
}
