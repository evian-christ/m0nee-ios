
//
//  SubscriptionSettingsView.swift
//  m0nee
//
//  Created by Chan on 26/05/2025.
//

import SwiftUI

struct SubscriptionSettingsView: View {
		@AppStorage("isProUser") var isProUser: Bool = false

		var body: some View {
				NavigationView {
						Form {
								Section(header: Text("Subscription Status")) {
										HStack {
												Text("Current Plan")
												Spacer()
												Text(isProUser ? "Monir Pro (Active)" : "Free")
														.foregroundColor(.secondary)
										}
								}
						}
						.navigationTitle("Monir Pro")
				}
		}
}

