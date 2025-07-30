//
//  ContentView.swift
//  ClerkiOS
//
//  Created by Alex on 2025-06-22.
//

import SwiftUI
import Clerk
import Supabase
import Auth

struct ContentView: View {
  @Environment(Clerk.self) private var clerk
  @EnvironmentObject private var subscriptionStore: SubscriptionStore

  var body: some View {
    VStack {
        //if let user = Auth.user{
      if let user = clerk.user {
        TopNavbar()
      } else {
        SignUpOrSignInView()
      }
    }
    .onAppear {
        Task {
            await subscriptionStore.syncWithDatabase()
        }
    }
  }
}

#Preview {
    ContentView()
}
