//
//  AddView.swift
//  iExpense
//
//  Created by Bora Kulak on 7.07.2026.
//

import SwiftUI
import PhotosUI
import Vision

/// Extracts a price/decimal amount from OCR-recognised receipt text.
enum ReceiptAmountParser {
    /// Returns the largest decimal number found in `text`, treating it as the
    /// receipt total. Handles both `.` and `,` decimal separators and ignores
    /// any leading currency symbols. Returns `nil` when no number is present.
    static func amount(from text: String) -> Double? {
        let pattern = "[0-9]+(?:[.,][0-9]{1,2})"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        var best: Double?
        regex.enumerateMatches(in: text, range: range) { match, _, _ in
            guard let match, let matchRange = Range(match.range, in: text) else { return }
            let normalized = text[matchRange].replacingOccurrences(of: ",", with: ".")
            if let value = Double(normalized) {
                if best == nil || value > best! {
                    best = value
                }
            }
        }
        return best
    }
}

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
                    PhotosPicker("Scan receipt for amount", selection: $receiptItem, matching: .images)
                    if isScanning {
                        Text("Scanning receipt…")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onChange(of: receiptItem) {
                Task { await scanReceipt() }
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

    /// Loads the selected receipt image, runs on-device text recognition and
    /// writes the detected price into the amount binding.
    private func scanReceipt() async {
        guard let receiptItem else { return }
        isScanning = true
        defer { isScanning = false }

        guard let data = try? await receiptItem.loadTransferable(type: Data.self),
              let cgImage = platformCGImage(from: data) else { return }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(cgImage: cgImage)
        try? handler.perform([request])

        let recognizedText = (request.results ?? [])
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")

        if let detected = ReceiptAmountParser.amount(from: recognizedText) {
            amount = detected
        }
    }

    private func platformCGImage(from data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}

#Preview {
    AddView(expenses: Expenses())
}
