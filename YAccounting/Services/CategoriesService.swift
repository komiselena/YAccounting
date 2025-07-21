//
//  CategoriesService.swift
//  YAccounting
//
//  Created by Mac on 07.06.2025.
//

import Foundation

@MainActor
final class CategoriesService: ObservableObject, CategoriesServiceProtocol {
    
    private let client: NetworkClient
    private let storage = CategorySwiftDataStorage()


    init(client: NetworkClient = NetworkClient()) {
        self.client = client
    }

    private var mockCategories: [Category] = [
        Category(id: 1, name: "Salary", emoji: "💸", isIncome: true),
        Category(id: 2, name: "House rent", emoji: "🏡", isIncome: false),
        Category(id: 3, name: "Products", emoji: "🥝", isIncome: false),
        Category(id: 4, name: "Car", emoji: "🚗", isIncome: false)

    ]
    
    var categories: [Category] = []
    
    func categories() async throws -> [Category] {
        do {
            let fetched: [Category] = try await client.request(endpoint: "api/v1/categories", method: "GET")
            try storage.saveCategories(fetched)
            return fetched
        } catch {
            return try storage.fetchCategories()
        }
    }

    func fetchDirectionCategories(by direction: Direction) async throws -> [Category]{
        let allCategories = try await categories()
        return allCategories.filter { $0.direction == direction}
    }
    
}

