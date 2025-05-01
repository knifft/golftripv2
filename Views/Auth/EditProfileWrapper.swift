import SwiftUI

struct EditProfileWrapper: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        if let user = authViewModel.currentUser {
            EditProfileView(user: user)
                .environmentObject(authViewModel)
        } else {
            ProgressView("Loading...")
        }
    }
}
//
//  EditProfileWrapper.swift
//  Goltripv2
//
//  Created by Travis Kniffen on 4/9/25.
//

