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
