//
//  YAccountingApp.swift
//  YAccounting
//
//  Created by Mac on 06.06.2025.
//

import SwiftUI
import SwiftData

@main
struct YAccountingApp: App {
    @Environment(\.scenePhase) private var scenePhase
            
        var body: some Scene {
            WindowGroup {
                MainTabView()
            }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background || newPhase == .inactive {
                Task {
                    let storage = TransactionSwiftDataStorage()
                    try? storage.saveContext()
                }
            }
        }
        
        
    }
}
