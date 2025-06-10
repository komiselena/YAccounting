//
//  YAccountingTests.swift
//  YAccountingTests
//
//  Created by Mac on 06.06.2025.
//

import Testing
@testable import YAccounting
import Foundation
import XCTest

struct YAccountingTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    func testJsonParsing() {
        let date = Date()
        let original = Transaction(accountId: 1, categoryId: 1, amount: 100.50, transactionDate: date, comment: "Test")
        
        let json = original.jsonObject
        let parsed = Transaction.parse(jsonObject: json)
        
        XCTAssertNotNil(parsed)
        XCTAssertEqual(original.accountId, parsed?.accountId)
        XCTAssertEqual(original.amount, parsed?.amount)
        XCTAssertEqual(original.comment, parsed?.comment)

    }
    
    func testInvalidJson() {
        let invalidJson: [String: Any] = [
            "accountId": "not a number",
            "categoryId": 2,
            "amount": 100.50,
            "transactionDate": "not a date",
            "comment": "test"
        ]
        
        XCTAssertNil(Transaction.parse(jsonObject: invalidJson))
    }
    
    func testBoundaryValuesParsing() {
        let bigAmount = Decimal(string: "1000000000000000")!
        let futureDate = Date.distantFuture
        let comment = String(repeating: "a", count: 1000)
        
        let transaction = Transaction(accountId: Int.max, categoryId: Int.min, amount: bigAmount, transactionDate: futureDate, comment: comment)
        
        let json = transaction.jsonObject
        let parsed = Transaction.parse(jsonObject: json)
        
        XCTAssertNotNil(parsed)
        XCTAssertEqual(transaction.accountId, parsed?.accountId)
        XCTAssertEqual(transaction.amount, parsed?.amount)
        
    }

}
