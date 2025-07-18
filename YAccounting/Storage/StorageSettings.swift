//
//  StorageSettings.swift
//  YAccounting
//
//  Created by Mac on 18.07.2025.
//

import Foundation

final class StorageSettings {
    static let shared = StorageSettings()
    
    var currentStorage: StorageType {
        get {
            let useCoreData = UserDefaults.standard.bool(forKey: "use_coredata_preference")
            return useCoreData ? .coreData : .swiftData
        }
        set {
            UserDefaults.standard.set(newValue == .coreData, forKey: "use_coredata_preference")
        }
    }
}
