//
//  MonthlySummary.swift
//  iExpense
//

import SwiftUI

/// Aggregates the expenses that fall in a given month. Amounts are kept apart
/// per currency so values in different currencies are never added together.
struct MonthlySummary {
    struct Total: Identifiable {
        let currency: String
        let amount: Double
        var id: String { currency }
    }

    struct CategoryTotal: Identifiable {
        let category: String
        let currency: String
        let amount: Double
        var id: String { "\(category)-\(currency)" }
    }

    let month: Date
    let totals: [Total]
    let categories: [CategoryTotal]
    /// Expenses saved before dates were tracked; they cannot be placed in any month.
    let undatedCount: Int

    init(items: [ExpenseItems], month: Date = .now, calendar: Calendar = .current) {
        self.month = month
        undatedCount = items.filter { $0.date == nil }.count

        let inMonth = items.filter { item in
            guard let date = item.date else { return false }
            return calendar.isDate(date, equalTo: month, toGranularity: .month)
        }

        var byCurrency = [String: Double]()
        var byCategory = [String: [String: Double]]()
        for item in inMonth {
            byCurrency[item.currency, default: 0] += item.amount
            byCategory[item.type, default: [:]][item.currency, default: 0] += item.amount
        }

        totals = byCurrency
            .map { Total(currency: $0.key, amount: $0.value) }
            .sorted { $0.currency < $1.currency }

        categories = byCategory
            .flatMap { category, currencies in
                currencies.map { CategoryTotal(category: category, currency: $0.key, amount: $0.value) }
            }
            .sorted { lhs, rhs in
                if lhs.category != rhs.category { return lhs.category < rhs.category }
                return lhs.currency < rhs.currency
            }
    }
}

struct MonthlySummaryView: View {
    let summary: MonthlySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(summary.month, format: .dateTime.month(.wide).year())
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if summary.totals.isEmpty {
                Text("No expenses this month")
                    .font(.headline)
            } else {
                ForEach(summary.totals) { total in
                    Text(total.amount, format: .currency(code: total.currency))
                        .font(.title.bold())
                }
            }

            if !summary.categories.isEmpty {
                Divider()

                ForEach(summary.categories) { line in
                    HStack {
                        Text(line.category)
                        Spacer()
                        Text(line.amount, format: .currency(code: line.currency))
                            .applyAmountStyle(for: line.amount)
                    }
                    .font(.subheadline)
                }
            }

            if summary.undatedCount > 0 {
                Text("\(summary.undatedCount) expense(s) saved without a date are not included.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        Section("Monthly Summary") {
            MonthlySummaryView(summary: MonthlySummary(items: [
                ExpenseItems(name: "Groceries", type: "Food", amount: 42.5),
                ExpenseItems(name: "Taxi", type: "Business", amount: 18, currency: "EUR"),
                ExpenseItems(name: "Old", type: "Personal", amount: 7, date: nil),
            ]))
        }
    }
}
