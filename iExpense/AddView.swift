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
    @State private var currency = "USD"
    
    var expenses: Expenses
    
    let types = ["Personal", "Business"]
        var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                
                Picker("Type", selection: $type){
                    ForEach(types, id: \.self) {
                        Text($0)
                    }
                }
                Picker("Currency", selection: $currency){
                    ForEach(Locale.commonISOCurrencyCodes, id: \.self) {
                        Text($0)
                    }
                    TextField("Amount", value: $amount, format: .currency(code: currency))
                        .keyboardType(.decimalPad)
                    
                }
                TextField("Amount", value: $amount, format: .currency(code: currency))
                    .keyboardType(.decimalPad)
            }
            .navigationTitle(Text("Add New Expense"))
            .toolbar {
                Button("Save") {
                    let item = ExpenseItems(name: name, type: type, amount: amount)
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
