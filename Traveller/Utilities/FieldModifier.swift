//
//  FieldModifier.swift
//  Traveller
//
//  Created by Sahil Prasad on 10/11/26.
//

import Foundation
import SwiftUI

struct TextFieldModifier:ViewModifier{
    func body(content:Content)->some View{
        content
            .padding()
            .font(.subheadline)
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.gray.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
}

struct ButtonFieldModifier:ViewModifier{
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .fontWeight(.bold)
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
    }
}
struct AlertItem: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

// MARK: - Alert ViewModifier
struct AlertViewModifier: ViewModifier {
    @Binding var alertItem: AlertItem?

    func body(content: Content) -> some View {
        content
            .alert(
                alertItem?.title ?? "",
                isPresented: Binding(
                    get: { alertItem != nil },
                    set: { if !$0 { alertItem = nil } }
                )
            ) {
                Button("OK", role: .cancel) {
                    alertItem = nil
                }
            } message: {
                if let message = alertItem?.message {
                    Text(message)
                }
            }
    }
}

extension View {
    func customAlert(item: Binding<AlertItem?>) -> some View {
        self.modifier(AlertViewModifier(alertItem: item))
    }
}

