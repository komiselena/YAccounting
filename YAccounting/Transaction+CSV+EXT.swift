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
        
        let columns = ["accountId", "categoryId", "amount", "transactionDate", "comment"]
        
        let header = lines[0].components(separatedBy: ",")
        guard header == columns else {
            print("CSV header doesn't match expected format. Expected: \(columns), got: \(header)")
            return nil
        }
        
        for line in lines.dropFirst() {
            let columns = line.components(separatedBy: ",")
            guard let accountId = Int(columns[0]),
                 let categoryId = Int(columns[1]),
                 let amount = Decimal(string: columns[2]),
                  let date = ISO8601DateFormatter().date(from: columns[3]) else {
                continue
            }
           let comment = columns[4]

            transactions.append(Transaction(accountId: accountId, categoryId: categoryId, amount: amount, transactionDate: date, comment: comment))
            
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
