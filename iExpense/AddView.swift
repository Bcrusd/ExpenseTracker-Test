//
//  AddView.swift
//  iExpense
//
//  Created by Bora Kulak on 7.07.2026.
//

import SwiftUI

 
struct AddView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var type = "Personal"
    @State private var amount = 0.0
    @State private var currency = ExpenseItems.defaultCurrency
    @State private var date = Date()
    
    var expenses: Expenses
    
    let types = ExpenseItems.categories
        var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                
                Picker("Category", selection: $type){
                    ForEach(types, id: \.self) {
                        Text($0)
                    }
                }
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Picker("Currency", selection: $currency){
                    ForEach(Locale.commonISOCurrencyCodes, id: \.self) {
                        Text($0)
                    }
                }
                TextField("Amount", value: $amount, format: .currency(code: currency))
                    .keyboardType(.decimalPad)
            }
            .navigationTitle(Text("Add New Expense"))
            .toolbar {
                Button("Save") {
                    let item = ExpenseItems(name: name, type: type, amount: amount, currency: currency, date: date)
                    expenses.items.append(item)
                    
                    dismiss()
                    
                }
            }
        }

    }
}

#Preview {
    AddView(expenses: Expenses())
}
