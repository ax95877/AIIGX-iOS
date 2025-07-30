//
//  ClerkiOSApp.swift
//  ClerkiOS
//
//  Created by Alex on 2025-06-22.
//

import SwiftUI
import Supabase
import Stripe
import GoogleSignIn

@main
struct ClerkiOSApp: App {
    @State private var supabaseClient = supabase
    @StateObject private var subscriptionStore = SubscriptionStore()

    var body: some Scene {
        WindowGroup {
          ZStack {
              ContentView()
          }
          .environmentObject(subscriptionStore)
          .onOpenURL { url in
              let stripeHandled = StripeAPI.handleURLCallback(with: url)
              if !stripeHandled {
                  GIDSignIn.sharedInstance.handle(url)
              }
          }
        }
      }
    }
