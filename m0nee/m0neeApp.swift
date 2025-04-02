//
//  m0neeApp.swift
//  m0nee
//
//  Created by Chan on 02/04/2025.
//

import SwiftUI

@main
struct m0neeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
