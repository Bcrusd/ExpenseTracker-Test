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
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var isProcessing = false
    
    @State private var name = ""
    @State private var type = "Personal"
    @State private var amount = 0.0
    @State private var currency = "USD"
    
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
                }
                
                TextField("Amount", value: $amount, format: .currency(code: currency))
                    .keyboardType(.decimalPad)
                
                
                Section {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack {
                            Image(systemName: "camera.viewfinder")
                                .foregroundColor(.blue)
                            Text(isProcessing ? "Processing..." : "Select Image")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle(Text("Add New Expense"))
            .onChange(of: selectedItem) {
                
                // If the user opens the gallery and closes it without selecting an image, cancel the process
                guard let currentItem = selectedItem else { return }
                
                // text "Processin" appear on the screen
                isProcessing = true
                
                //Start thread(task) to run in background
                // Start thread(task) to run in background
                Task {
                    // 1. Veriyi indiriyoruz (if let yerine guard let kullanarak kodu daha temiz hale getirdik)
                    guard let data = try? await currentItem.loadTransferable(type: Data.self) else {
                        print("Error: Could not retrieve photo data")
                        Task { @MainActor in isProcessing = false }
                        return
                    }
                    
                    print("Success: Photo data was taken! Size: \(data.count) byte")
                    
                    // 2. Data'yı UIImage'e, oradan da Vision'ın anlayacağı CGImage'e çeviriyoruz
                    guard let uiImage = UIImage(data: data),
                          let cgImage = uiImage.cgImage else {
                        print("Hata: Görsel Data'dan CGImage'e dönüştürülemedi.")
                        Task { @MainActor in isProcessing = false }
                        return
                    }
                    
                    // 3. Vision Metin Tanıma İsteğini (Request) Hazırlıyoruz
                    let request = VNRecognizeTextRequest { request, error in
                        if let error = error {
                            print("Vision Hatası: \(error.localizedDescription)")
                            Task { @MainActor in isProcessing = false }
                            return
                        }
                        
                        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
                        
                        // Taranan tüm satırları birleştirip tek bir String yapıyoruz
                        let recognizedText = observations.compactMap { observation in
                            observation.topCandidates(1).first?.string
                        }.joined(separator: "\n")
                        
                        print("Taranan Fiş Metni:\n\(recognizedText)")
                        
                        // İşlem başarıyla bitti, yükleniyor yazısını kaldırıyoruz
                        Task { @MainActor in
                            isProcessing = false
                        }
                    }
                    
                    // Doğruluk oranını maksimuma alıyoruz
                    request.recognitionLevel = .accurate
                    request.usesLanguageCorrection = true
                    
                    // 4. İsteği Çalıştırıyoruz
                    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    
                    do {
                        try handler.perform([request])
                    } catch {
                        print("Vision isteği gerçekleştirilemedi: \(error.localizedDescription)")
                        Task { @MainActor in isProcessing = false }
                    }
                }
            
            }
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
