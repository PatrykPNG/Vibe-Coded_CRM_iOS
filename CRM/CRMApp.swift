//
//  CRMApp.swift
//  CRM
//
//  Created by Patryk Ostrowski on 20/03/2026.
//

import SwiftUI
import SwiftData

@main
struct CRMApp: App {
    let container: ModelContainer = {
        let schema = Schema([Contact.self, Interaction.self, Tag.self, Deal.self])
        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        return try! ModelContainer(for: schema, configurations: config)
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    await NotificationService.shared.requestPermission()
                }
        }
        .modelContainer(container)
    }
}
