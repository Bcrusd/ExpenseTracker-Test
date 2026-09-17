//
//  ContentView.swift
//  iExpense
//
//  Created by Bora Kulak on 26.05.2026.
//
import SwiftUI
import Observation


struct ExpenseItems: Identifiable, Codable {
    static let categories = ["Food", "Personal", "Business", "Transport", "Entertainment", "Other"]
    static let defaultCurrency = "USD"

    var id = UUID()
    let name: String
    let type: String
    let amount: Double
    var currency = ExpenseItems.defaultCurrency
    var date: Date? = Date()

    enum CodingKeys: String, CodingKey {
        case id, name, type, amount, currency, date
    }
}

extension ExpenseItems {
    /// Expenses saved before `currency` and `date` existed decode with the default
    /// currency and no date, so items already stored in UserDefaults are kept.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        type = try container.decode(String.self, forKey: .type)
        amount = try container.decode(Double.self, forKey: .amount)
        currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? ExpenseItems.defaultCurrency
        date = try container.decodeIfPresent(Date.self, forKey: .date)
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
}

struct ContentView: View {
   @State private var expenses = Expenses()
    
   @State private var showingAddExpense = false
        var body: some View {
            NavigationStack {
                List {
                    Section("Monthly Summary") {
                        MonthlySummaryView(summary: MonthlySummary(items: expenses.items))
                    }
                    
                    Section("Expenses") {
                        ForEach(expenses.items){ item in
                            HStack{
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .font(.headline)
                                    
                                    Text(item.type)
                                    
                                    if let date = item.date {
                                        Text(date, format: .dateTime.day().month().year())
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text(item.amount, format: .currency(code: item.currency))
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
