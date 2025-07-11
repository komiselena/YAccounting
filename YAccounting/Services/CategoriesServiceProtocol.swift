//
//  CategoriesServiceProtocol.swift
//  YAccounting
//
//  Created by Mac on 28.06.2025.
//


import Foundation

protocol CategoriesServiceProtocol {
    
    func categories() async throws -> [Category]
    func fetchDirectionCategories(by direction: Direction) async throws -> [Category]
    
}
