//
//  SupportSettingsView.swift
//  m0nee
//
//  Created by Chan on 27/06/2025.
//

import SwiftUI

struct SupportSettingsView: View {
		var body: some View {
				List {
						NavigationLink(destination: Text("Contact Us Page")) {
								Label("Contact Us", systemImage: "envelope")
						}

						NavigationLink(destination: Text("Terms of Use Page")) {
								Label("Terms of Use", systemImage: "doc.text")
						}

						NavigationLink(destination: Text("Privacy Policy Page")) {
								Label("Privacy Policy", systemImage: "lock")
						}
				}
				.navigationTitle("Help & Support")
		}
}

#Preview {
		NavigationView {
				SupportSettingsView()
		}
}
