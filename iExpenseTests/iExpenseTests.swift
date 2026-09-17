//
//  iExpenseTests.swift
//  iExpenseTests
//
//  Created by Bora Kulak on 26.05.2026.
//

import Foundation
import Testing
@testable import iExpense

@MainActor
struct iExpenseTests {

    @Test func legacyItemsDecodeWithoutDateOrCurrency() throws {
        let legacy = Data("""
        [{"id":"5A2A6D5E-7E0F-4D7E-9D6C-0A1B2C3D4E5F","name":"Coffee","type":"Personal","amount":3.5}]
        """.utf8)

        let items = try JSONDecoder().decode([ExpenseItems].self, from: legacy)

        #expect(items.count == 1)
        #expect(items[0].name == "Coffee")
        #expect(items[0].type == "Personal")
        #expect(items[0].amount == 3.5)
        #expect(items[0].currency == "USD")
        #expect(items[0].date == nil)
    }

    @Test func itemsRoundTripWithDateAndCurrency() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let item = ExpenseItems(name: "Lunch", type: "Food", amount: 12, currency: "EUR", date: date)

        let data = try JSONEncoder().encode([item])
        let decoded = try JSONDecoder().decode([ExpenseItems].self, from: data)

        #expect(decoded.count == 1)
        #expect(decoded.first?.id == item.id)
        #expect(decoded.first?.currency == "EUR")
        #expect(decoded.first?.date == date)
    }

    @Test func monthlySummaryGroupsMonthByCategoryAndCurrency() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        let march10 = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 10)))
        let march25 = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 25)))
        let feb28 = try #require(calendar.date(from: DateComponents(year: 2026, month: 2, day: 28)))

        let items = [
            ExpenseItems(name: "Groceries", type: "Food", amount: 40, date: march10),
            ExpenseItems(name: "Dinner", type: "Food", amount: 25, date: march25),
            ExpenseItems(name: "Taxi", type: "Business", amount: 15, currency: "EUR", date: march25),
            ExpenseItems(name: "Last month", type: "Personal", amount: 99, date: feb28),
            ExpenseItems(name: "Legacy", type: "Personal", amount: 7, date: nil),
        ]

        let summary = MonthlySummary(items: items, month: march10, calendar: calendar)

        #expect(summary.totals.map(\.currency) == ["EUR", "USD"])
        #expect(summary.totals.first { $0.currency == "USD" }?.amount == 65)
        #expect(summary.totals.first { $0.currency == "EUR" }?.amount == 15)
        #expect(summary.categories.map(\.category) == ["Business", "Food"])
        #expect(summary.categories.first { $0.category == "Food" }?.amount == 65)
        #expect(summary.categories.first { $0.category == "Business" }?.currency == "EUR")
        #expect(summary.undatedCount == 1)
    }

}
