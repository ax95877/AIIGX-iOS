//
//  ContentView.swift
//  ClerkiOS
//
//  Created by Alex on 2025-06-22.
//

import SwiftUI
import Supabase

struct ContentView: View {
  @State var session: Session?
  @EnvironmentObject private var subscriptionStore: SubscriptionStore

  func signOut() {
      Task {
          do {
              try await supabase.auth.signOut()
              self.session = nil
          } catch {
              dump(error)
          }
      }
  }

  var body: some View {
    VStack {
      if session != nil {
        TopNavbar(signOut: signOut)
      } else {
        SignUpOrSignInView()
      }
    }
    .onAppear {
        Task {
            for await state in await supabase.auth.authStateChanges {
                if [.initialSession, .signedIn, .signedOut].contains(state.event) {
                    self.session = state.session
                }
            }
        }
    }
  }
}

#Preview {
    ContentView()
}
