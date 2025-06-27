//
//  StatesViewModel.swift
//  YAccounting
//
//  Created by Mac on 27.06.2025.
//

import SwiftUI

final class StatesViewModel: ObservableObject {
    private var categoryService = CategoriesService() // Fixed: Removed @StateObject
    
    @Published var search = "" {
        didSet {
            filterResults()
        }
    }
    @Published var allStates: [Category] = []
    @Published var filteredStates: [Category] = []
    
    func filterResults() {
        if search.isEmpty {
            filteredStates = allStates
        } else {
            filteredStates = allStates
                .map { (state: $0, score: fuzzyMatchScore(search, in: $0.name)) }
                .filter { $0.score > 0 }
                .sorted { $0.score > $1.score }
                .map { $0.state }
        }
    }
    
    func loadStates() async {
        do {
            allStates = try await categoryService.categories()
            filterResults()
        } catch {
            print("Error loading states: \(error.localizedDescription)")
        }
    }
    
    private func fuzzyMatchScore(_ pattern: String, in text: String) -> Int {
        guard !pattern.isEmpty else { return 1 }
        let pattern = pattern.lowercased()
        let text = text.lowercased()
        
        var patternIndex = pattern.startIndex
        var textIndex = text.startIndex
        var matches: [String.Index] = []
        
        // Find all matches in order
        while textIndex < text.endIndex && patternIndex < pattern.endIndex {
            if text[textIndex] == pattern[patternIndex] {
                matches.append(textIndex)
                patternIndex = pattern.index(after: patternIndex)
            }
            textIndex = text.index(after: textIndex)
        }
        
        // Calculate score based on matches
        var score = 0
        for (i, matchIndex) in matches.enumerated() {
            score += 10  // Base match score
            
            // Consecutive bonus
            if i > 0 {
                let prevIndex = matches[i-1]
                if text.index(after: prevIndex) == matchIndex {
                    score += 5
                }
            }
            
            // Start-of-word bonus
            if matchIndex == text.startIndex || text[text.index(before: matchIndex)] == " " {
                score += 3
            }
        }
        
        // Penalty for unmatched characters
        let unmatchedCount = pattern.distance(from: patternIndex, to: pattern.endIndex)
        return unmatchedCount == 0 ? score : max(0, score - (unmatchedCount * 2))
    }
}
