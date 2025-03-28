//
//  Eminent_NotesApp.swift
//  Eminent Notes
//
//  Created by Gabriel on 3/28/25.
//

import SwiftUI

@main
struct Eminent_NotesApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
