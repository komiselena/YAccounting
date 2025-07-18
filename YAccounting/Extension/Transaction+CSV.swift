//
//  Transaction+CSV+EXT.swift
//  YAccounting
//
//  Created by Mac on 08.06.2025.
//

import Foundation

extension Transaction {
    static func parse(csvString: String) -> [Transaction]? {
        let lines = csvString.components(separatedBy: .newlines)
        guard !lines.isEmpty else { return nil }
        
        var transactions: [Transaction] = []
        
        let columns = ["id", "accountId", "categoryId", "amount", "transactionDate", "comment", "createdAt", "updatedAt"]
        
        let header = lines[0].components(separatedBy: ",")
        guard header == columns else {
            print("CSV header doesn't match expected format. Expected: \(columns), got: \(header)")
            return nil
        }
        
        for line in lines.dropFirst() {
            let columns = line.components(separatedBy: ",")
            guard let id = Int(columns[0]),
                  let accountId = Int(columns[1]),
                  let categoryId = Int(columns[2]),
                  let amount = Decimal(string: columns[3]),
                  let date = ISO8601DateFormatter().date(from: columns[4]),
                  let createdAt = ISO8601DateFormatter().date(from: columns[6]),
                  let updatedAt = ISO8601DateFormatter().date(from: columns[7])
                    
            else {
                continue
            }
            let comment = columns[5]
            
            transactions.append(Transaction(id: id, accountId: accountId, categoryId: categoryId, amount: String(describing: amount), transactionDate: date, comment: comment, createdAt: createdAt, updatedAt: updatedAt))
            
        }
        
        return transactions.isEmpty ? nil : transactions
        
    }
    
    static func read(csvFileName: String) -> [Transaction]? {
        guard let filePath = Bundle.main.path(forResource: csvFileName, ofType: "csv") else {
            return nil
        }
        
        do{
            let csvString = try String(contentsOfFile: filePath, encoding: .utf8)
            return parse(csvString: csvString)
        }catch{
            print("Error reading file: \(csvFileName)")
            return nil
        }
        
    }
}
