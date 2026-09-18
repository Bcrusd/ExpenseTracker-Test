//
//  AddView.swift
//  iExpense
//
//  Created by Bora Kulak on 7.07.2026.
//

import SwiftUI
import PhotosUI
import Vision

/// Parses the most likely price from lines of OCR-recognised receipt text.
///
/// Returns the largest decimal-looking number found, which is a reasonable
/// heuristic for a receipt total. Returns `nil` when no number is present.
func parseAmount(from recognizedStrings: [String]) -> Double? {
    let pattern = #"\d+(?:[.,]\d{1,2})?"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

    var candidates: [Double] = []
    for line in recognizedStrings {
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        for match in regex.matches(in: line, range: range) {
            guard let matchRange = Range(match.range, in: line) else { continue }
            let token = line[matchRange].replacingOccurrences(of: ",", with: ".")
            if let value = Double(token) {
                candidates.append(value)
            }
        }
    }

    return candidates.max()
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

                PhotosPicker("Scan Receipt", selection: $receiptItem, matching: .images)
            }
            .onChange(of: receiptItem) { _, newItem in
                Task { await scanReceipt(newItem) }
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

    /// Loads the picked image, runs Vision text recognition, and writes the
    /// parsed price into `amount`.
    private func scanReceipt(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let cgImage = platformCGImage(from: data) else { return }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false

        let handler = VNImageRequestHandler(cgImage: cgImage)
        try? handler.perform([request])

        let recognizedStrings = (request.results ?? []).compactMap {
            $0.topCandidates(1).first?.string
        }

        if let parsed = parseAmount(from: recognizedStrings) {
            await MainActor.run { amount = parsed }
        }
    }
}

private func platformCGImage(from data: Data) -> CGImage? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(source, 0, nil)
}

#Preview {
    AddView(expenses: Expenses())
}
