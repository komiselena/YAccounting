//
//  CategoriesService.swift
//  YAccounting
//
//  Created by Mac on 07.06.2025.
//

import Foundation


final class CategoriesService {
    func categories() async throws -> [Category] {
        [
            Category(id: 1, name: "Salary", emoji: "💸", isIncome: true),
            Category(id: 2, name: "House rent", emoji: "🏡", isIncome: false),
            Category(id: 3, name: "Products", emoji: "🥝", isIncome: false),
            Category(id: 4, name: "Car", emoji: "🚗", isIncome: false)

            
        ]
    }
    
    func fetchDirectionCategories(by direction: Direction) async throws -> [Category]{
        let allCategories = try await categories()
        return allCategories.filter { $0.direction == direction}
    }
    
}
