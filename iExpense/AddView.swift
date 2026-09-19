//
//  AddView.swift
//  iExpense
//
//  Created by Bora Kulak on 7.07.2026.
//

import SwiftUI
import PhotosUI
import Vision

// Scans recognised receipt text for a monetary value and returns the largest
// candidate found (receipt totals are typically the largest amount). Returns
// nil when no decimal/price-like number is present.
func parsePrice(from text: String) -> Double? {
    let pattern = #"\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})|\d+[.,]\d{2}|\d+"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    var best: Double?
    for match in regex.matches(in: text, range: range) {
        guard let matchRange = Range(match.range, in: text) else { continue }
        var token = String(text[matchRange])
        // Normalise decimal separators: strip thousands separators, keep the
        // last separator as the decimal point.
        if let lastSeparator = token.lastIndex(where: { $0 == "." || $0 == "," }) {
            let decimals = token.distance(from: token.index(after: lastSeparator), to: token.endIndex)
            if decimals == 2 {
                var chars = Array(token)
                chars[token.distance(from: token.startIndex, to: lastSeparator)] = "."
                token = String(chars).replacingOccurrences(of: ",", with: "")
                token = token.replacingOccurrences(of: ".", with: "", range: token.startIndex..<token.index(token.startIndex, offsetBy: token.distance(from: token.startIndex, to: token.firstIndex(of: ".")!)))
            }
        }
        guard let value = Double(token) else { continue }
        if best == nil || value > best! {
            best = value
        }
    }
    return best
}

// Runs on-device text recognition over the given image data and returns the
// concatenated recognised strings.
func recognizeText(in imageData: Data, completion: @escaping (String) -> Void) {
    guard let uiImage = UIImage(data: imageData), let cgImage = uiImage.cgImage else {
        completion("")
        return
    }
    let request = VNRecognizeTextRequest { request, _ in
        let observations = request.results as? [VNRecognizedTextObservation] ?? []
        let text = observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
        DispatchQueue.main.async { completion(text) }
    }
    request.recognitionLevel = .accurate
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    DispatchQueue.global(qos: .userInitiated).async {
        try? handler.perform([request])
    }
}

struct AddView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var type = "Personal"
    @State private var amount = 0.0
    @State private var currency = "USD"
    
    @State private var receiptItem: PhotosPickerItem?
    
    var expenses: Expenses
    
    let types = ["Food", "Personal", "Business"]
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
                
                PhotosPicker("Scan receipt", selection: $receiptItem, matching: .images)
            }
            .onChange(of: receiptItem) {
                Task {
                    guard let data = try? await receiptItem?.loadTransferable(type: Data.self) else { return }
                    recognizeText(in: data) { text in
                        if let price = parsePrice(from: text) {
                            amount = price
                        }
                    }
                }
            }
            .navigationTitle(Text("Add New Expense"))
            .toolbar {
                Button("Save") {
                    let item = ExpenseItems(name: name, type: type, amount: amount, date: Date())
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
