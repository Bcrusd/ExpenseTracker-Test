//
//  iExpenseTests.swift
//  iExpenseTests
//
//  Created by Bora Kulak on 26.05.2026.
//

import Foundation
import Testing
@testable import iExpense

struct iExpenseTests {

    @Test func currentMonthTotalSumsOnlyThisMonth() async throws {
        let now = Date()
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: now)!

        let expenses = Expenses()
        expenses.items = [
            ExpenseItems(name: "Lunch", type: "Food", amount: 12, date: now),
            ExpenseItems(name: "Books", type: "Personal", amount: 30, date: now),
            ExpenseItems(name: "Old", type: "Business", amount: 99, date: lastMonth)
        ]

        #expect(expenses.currentMonthTotal == 42)
    }

    @Test func categoryBreakdownGroupsCurrentMonthByType() async throws {
        let now = Date()

        let expenses = Expenses()
        expenses.items = [
            ExpenseItems(name: "Lunch", type: "Food", amount: 12, date: now),
            ExpenseItems(name: "Dinner", type: "Food", amount: 8, date: now),
            ExpenseItems(name: "Books", type: "Personal", amount: 30, date: now)
        ]

        let breakdown = expenses.currentMonthTotalsByCategory
        #expect(breakdown.count == 2)
        #expect(breakdown.first { $0.category == "Food" }?.total == 20)
        #expect(breakdown.first { $0.category == "Personal" }?.total == 30)
    }

    @Test func legacyRecordsWithoutDateStillDecode() async throws {
        // Simulates data persisted before the `date` field existed.
        let legacyJSON = "[{\"id\":\"D5C4C1D2-6C0C-4B1F-9A2E-000000000001\",\"name\":\"Legacy\",\"type\":\"Personal\",\"amount\":25}]"
        let data = Data(legacyJSON.utf8)

        let decoded = try JSONDecoder().decode([ExpenseItems].self, from: data)
        #expect(decoded.count == 1)
        #expect(decoded[0].name == "Legacy")
        #expect(decoded[0].amount == 25)
        // Missing date defaults to now, so the record counts toward this month.
        #expect(Calendar.current.isDate(decoded[0].date, equalTo: Date(), toGranularity: .month))
    }

    @Test func parsePriceExtractsLargestAmountFromReceiptText() async throws {
        let receipt = """
        MARKET
        Milk 3.50
        Bread 2.25
        TOTAL 42.75
        """
        #expect(parsePrice(from: receipt) == 42.75)
    }

    @Test func parsePriceReturnsNilWhenNoNumberPresent() async throws {
        #expect(parsePrice(from: "No numbers here") == nil)
    }

}
