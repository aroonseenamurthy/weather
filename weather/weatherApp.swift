//
//  weatherApp.swift
//  weather
//
//  Created by Programmer on 6/21/26.
//

import SwiftUI
import CoreData

@main
struct weatherApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
