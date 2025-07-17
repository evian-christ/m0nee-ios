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
						Link(destination: URL(string: "https://ckim.dev/monir/main")!) {
								Label("Q&A", systemImage: "questionmark.circle")
						}
						
						Link(destination: URL(string: "mailto:monir.careteam@gmail.com")!) {
								Label("Contact Us", systemImage: "envelope")
						}

						Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
								Label("Terms of Use", systemImage: "doc.text")
						}

						Link(destination: URL(string: "https://ckim.dev/monir/privacy")!) {
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
