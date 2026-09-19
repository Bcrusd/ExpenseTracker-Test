//
//  AddView.swift
//  iExpense
//
//  Created by Bora Kulak on 7.07.2026.
//

import SwiftUI
import PhotosUI
import Vision

 
struct AddView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var type = "Personal"
    @State private var amount = 0.0
    @State private var currency = "USD"
    @State private var receiptItem: PhotosPickerItem?
    @State private var isScanning = false
    
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
                
                Section("Receipt") {
                    PhotosPicker("Scan receipt image", selection: $receiptItem, matching: .images)
                    if isScanning {
                        Text("Scanning…")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onChange(of: receiptItem) { _, newItem in
                guard let newItem else { return }
                scanReceipt(newItem)
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
    
    private func scanReceipt(_ item: PhotosPickerItem) {
        isScanning = true
        Task {
            defer { isScanning = false }
            guard
                let data = try? await item.loadTransferable(type: Data.self),
                let cgImage = platformCGImage(from: data)
            else { return }
            
            if let total = Self.recognizeTotal(in: cgImage) {
                amount = total
            }
        }
    }
    
    private func platformCGImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
    
    /// Runs Vision OCR on the image and returns the largest decimal price found,
    /// which for a receipt is very likely the total.
    static func recognizeTotal(in cgImage: CGImage) -> Double? {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        guard (try? handler.perform([request])) != nil,
              let observations = request.results else { return nil }
        
        let lines = observations.compactMap { $0.topCandidates(1).first?.string }
        return parseTotal(from: lines)
    }
    
    /// Extracts the most likely total from recognised receipt lines: the largest
    /// decimal number (e.g. "12.34", "1,234.56") appearing in the text.
    static func parseTotal(from lines: [String]) -> Double? {
        let pattern = #"\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})|\d+[.,]\d{2}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        
        var amounts: [Double] = []
        for line in lines {
            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            regex.enumerateMatches(in: line, range: range) { match, _, _ in
                guard let match, let matchRange = Range(match.range, in: line) else { return }
                let raw = String(line[matchRange])
                if let value = normalizedAmount(raw) {
                    amounts.append(value)
                }
            }
        }
        return amounts.max()
    }
    
    /// Normalises a matched price string into a Double, handling both
    /// "." and "," as the decimal/grouping separators.
    static func normalizedAmount(_ raw: String) -> Double? {
        var value = raw
        // Treat the last separator as the decimal point, drop the rest (grouping).
        if let lastSeparatorIndex = value.lastIndex(where: { $0 == "." || $0 == "," }) {
            let decimalPart = value[value.index(after: lastSeparatorIndex)...]
            var integerPart = String(value[value.startIndex..<lastSeparatorIndex])
            integerPart.removeAll { $0 == "." || $0 == "," }
            value = integerPart + "." + decimalPart
        }
        return Double(value)
    }
}

#Preview {
    AddView(expenses: Expenses())
}
