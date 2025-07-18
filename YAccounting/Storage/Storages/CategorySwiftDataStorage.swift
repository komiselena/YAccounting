//
//  CategorySwiftDataStorage.swift
//  YAccounting
//
//  Created by Mac on 18.07.2025.
//


import Foundation
import SwiftData

@MainActor
final class CategorySwiftDataStorage {
    let container: ModelContainer
    let modelContext: ModelContext
    
    init() {
        do {
            let config = ModelConfiguration("CategoryData", schema: Schema([CategoryModel.self]))
            container = try ModelContainer(for: CategoryModel.self, configurations: config)
            modelContext = ModelContext(container)
        } catch {
            fatalError("Failed to create CategoryData container: \(error)")
        }
    }
    
    func saveCategories(_ categories: [Category]) throws {
        for category in categories {
            let model = CategoryModel(from: category)
            modelContext.insert(model)
        }
        try modelContext.save()
    }
    
    func fetchCategories() throws -> [Category] {
        let models = try modelContext.fetch(FetchDescriptor<CategoryModel>())
        return models.map { $0.toCategory() }
    }
}

