//
//  ContentView.swift
//  iExpense
//
//  Created by Bora Kulak on 26.05.2026.
//
import SwiftUI
import Observation


struct ExpenseItems: Identifiable, Codable {
    var id = UUID()
    let name: String
    let type: String
    let amount: Double
    var date: Date

    init(id: UUID = UUID(), name: String, type: String, amount: Double, date: Date = Date()) {
        self.id = id
        self.name = name
        self.type = type
        self.amount = amount
        self.date = date
    }

    // Backward-compatible decoding: records saved before `date` existed
    // are still readable and are treated as belonging to the current month.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        amount = try container.decode(Double.self, forKey: .amount)
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
    }
}


struct AmountStyle: ViewModifier {
    let amount: Double
    
    func body(content: Content) -> some View {
        content
            .foregroundStyle(amount < 10 ? .green : (amount < 100 ? .orange : .red))
            .fontWeight(amount < 10 ? .regular : (amount < 100 ? .semibold : .black))
    }
}

extension View {
    func applyAmountStyle(for amount: Double) -> some View {
        self.modifier(AmountStyle(amount: amount))
    }
}

@Observable
class Expenses {
    var items = [ExpenseItems]() {
        didSet {
            if let encoded = try? JSONEncoder().encode(items) {
                UserDefaults.standard.set(encoded, forKey: "Items")
            }
        }
    }
      
    init() {
        if let savedItems = UserDefaults.standard.data(forKey: "Items") {
            if let decodedItems = try? JSONDecoder().decode([ExpenseItems].self, from: savedItems) {
                items = decodedItems
                return
            }
        }
        
        items = []
    }

    /// Items dated within the current calendar month.
    var currentMonthItems: [ExpenseItems] {
        let calendar = Calendar.current
        let now = Date()
        return items.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
    }

    /// Total spend for the current month.
    var currentMonthTotal: Double {
        currentMonthItems.reduce(0) { $0 + $1.amount }
    }

    /// Current-month spend grouped by category (`type`), sorted by category name.
    var currentMonthTotalsByCategory: [(category: String, total: Double)] {
        var totals: [String: Double] = [:]
        for item in currentMonthItems {
            totals[item.type, default: 0] += item.amount
        }
        return totals
            .map { (category: $0.key, total: $0.value) }
            .sorted { $0.category < $1.category }
    }
}

struct ContentView: View {
   @State private var expenses = Expenses()
    
   @State private var showingAddExpense = false
        var body: some View {
            NavigationStack {
                List {
                    Section("Monthly Summary") {
                        HStack {
                            Text("This Month")
                                .font(.headline)
                            Spacer()
                            Text(expenses.currentMonthTotal, format: .currency(code: "USD"))
                                .font(.headline)
                        }
                    }

                    if !expenses.currentMonthTotalsByCategory.isEmpty {
                        Section("Category Breakdown") {
                            ForEach(expenses.currentMonthTotalsByCategory, id: \.category) { entry in
                                HStack {
                                    Text(entry.category)
                                    Spacer()
                                    Text(entry.total, format: .currency(code: "USD"))
                                        .applyAmountStyle(for: entry.total)
                                }
                            }
                        }
                    }

                    Section("All Expenses") {
                    ForEach(expenses.items){ item in
                        HStack{
                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.headline)
                                
                                Text(item.type)
                            }
                            
                            Spacer()
                            
                            Text(item.amount, format: .currency(code: "USD"))
                                .applyAmountStyle(for: item.amount)
                            
                        }
                        
                        
                        
                        
                    }
                    .onDelete(perform: removeItems)
                    }
                }.navigationTitle("iExpense")
                    .toolbar {
                        Button("Add Expense", systemImage: "plus") {
                            showingAddExpense = true
                        }
                    }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddView(expenses: expenses)
            }
            
        }
    
    func removeItems(at offsets: IndexSet) {
        expenses.items.remove(atOffsets: offsets)
    }
    
}

#Preview {
    ContentView()
}
