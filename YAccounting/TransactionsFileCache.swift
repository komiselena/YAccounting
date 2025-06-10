//
//  TransactionsFileCache.swift
//  YAccounting
//
//  Created by Mac on 07.06.2025.
//

import Foundation


final class TransactionsFileCache {
        
    private(set) var transactions: [Transaction] = []
    
    private let fileName: String
    
    init(fileName: String = "transactions") {
        self.fileName = fileName
        loadFromFile()
    }
    
    func addTransaction(_ transaction: Transaction) throws  {
        if transactions.contains(where: { $0.id == transaction.id }) {
            throw CacheError.duplicateTransaction
        }
        
        transactions.append(transaction)
        try saveToFile()
    }
    
    func deleteTransaction(id: Int) throws {
        transactions.removeAll(where: { $0.id == id})
        try saveToFile()
    }
    
    func saveToFile() throws {
        let jsonObjects = transactions.map { $0.jsonObject }
        let data = try JSONSerialization.data(withJSONObject: jsonObjects, options: .prettyPrinted)
        
        guard let jsonFile = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw CacheError.fileError
        }
        
        let fileURL = jsonFile.appendingPathComponent("\(fileName).json")
        try data.write(to: fileURL)
        
    }
    
    func loadFromFile() {
        guard let jsonFile = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fileURL = jsonFile.appendingPathComponent("\(fileName).json")

        do{
            let data = try Data(contentsOf: fileURL)
            let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            
            transactions = jsonArray?.compactMap { Transaction.parse(jsonObject: $0) } ?? []
        }catch{
            transactions = []
        }

    }
    
    enum CacheError: Error{
        case duplicateTransaction
        case fileError
    }
}
