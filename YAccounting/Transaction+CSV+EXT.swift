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
        
        let columns = ["id", "accountId", "accountName", "accountBalance", "accountCurrency", "categoryId", "categoryName", "categoryEmoji", "categoryIsIncome", "amount", "transactionDate", "comment", "createdAt", "updatedAt"]
        
        let header = lines[0].components(separatedBy: ",")
        guard header == columns else {
            print("CSV header doesn't match expected format. Expected: \(columns), got: \(header)")
            return nil
        }
        
        for line in lines.dropFirst() {
            let columns = line.components(separatedBy: ",")
            guard columns.count >= 14 else { continue }

            guard let id = Int(columns[0]),
                  let accountId = Int(columns[1]),
                  let accountBalance = Decimal(string: columns[3]),
                  let categoryId = Int(columns[5]),
                  let categoryIsIncome = Bool(columns[8].lowercased()),
                  let amount = Decimal(string: columns[9]) else {
                continue
            }

            let dateFormatter = ISO8601DateFormatter()
            guard let transactionDate = dateFormatter.date(from: columns[10]),
                  let createdAt = dateFormatter.date(from: columns[12]),
                  let updatedAt = dateFormatter.date(from: columns[13]) else {
                continue
            }

            let emojiString = columns[7]
            guard !emojiString.isEmpty, let emojiChar = emojiString.first else {
                continue
            }

            let comment = columns[11]

            let account = Account(
                id: accountId,
                name: columns[2],
                balance: accountBalance,
                currency: columns[4]
            )
            
            let category = Category(
                id: categoryId,
                name: columns[6],
                emoji: emojiChar,
                isIncome: categoryIsIncome
            )
            
            let transaction = Transaction(
                id: id,
                account: account,
                category: category,
                amount: amount,
                transactionDate: transactionDate,
                comment: comment,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
            
            transactions.append(transaction)
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
