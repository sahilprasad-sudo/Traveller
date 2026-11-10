//
//  GoogleSignIn.swift
//  Traveller
//
//  Created by Sahil Prasad on 11/11/26.
//

import Foundation
import UIKit

final class GoogleSignInUtil{
    static let shared = GoogleSignInUtil()
    
    private init(){
        
    }
    
   

   
        /// Returns the topmost view controller in the active window hierarchy.
    ///
        @MainActor
         func topViewController(base: UIViewController? = nil) -> UIViewController? {
            let root: UIViewController?
            
            if let base = base {
                root = base
            } else {
                // Retrieve key window across iOS 13+ scenes safely
                let activeWindow = UIApplication.shared.connectedScenes
                    .filter { $0.activationState == .foregroundActive }
                    .compactMap { $0 as? UIWindowScene }
                    .first?
                    .windows
                    .first(where: { $0.isKeyWindow })
                
                root = activeWindow?.rootViewController
            }
            
            // Traverse Navigation Controllers
            if let nav = root as? UINavigationController {
                return topViewController(base: nav.visibleViewController)
            }
            
            // Traverse Tab Bar Controllers
            if let tab = root as? UITabBarController {
                if let selected = tab.selectedViewController {
                    return topViewController(base: selected)
                }
            }
            
            // Traverse Modals / Sheets
            if let presented = root?.presentedViewController {
                return topViewController(base: presented)
            }
            
            return root
        }
    

}
