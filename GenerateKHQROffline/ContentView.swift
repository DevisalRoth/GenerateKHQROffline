//
//  ContentView.swift
//  GenerateKHQROffline
//
//  Created by Visalroth on 25/12/25.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import BakongKHQR

struct ContentView: View {

    // MARK: - Input fields
    @State private var storeName: String = "Coffee Shop"
    @State private var accountInfo: String = "85512233455"
    @State private var amountText: String = ""

    // MARK: - Output
    @State private var khqrString: String = ""
    @State private var qrImage: UIImage? = nil
    @State private var errorMessage: String = ""

    // MARK: - QR generator
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 15) {

                    Text("Offline KHQR")
                        .font(.system(size: 38, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)

                    // ✅ Error label
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.system(size: 14, weight: .semibold))
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // ✅ Merchant info
                    GroupBox(label: Text("Merchant Info")) {
                        VStack(spacing: 10) {
                            TextField("Store Name", text: $storeName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            TextField("Account Information", text: $accountInfo)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.top, 5)
                    }

                    // ✅ Amount input (offline)
                    GroupBox(label: Text("Amount (Offline Input)")) {
                        VStack(spacing: 10) {
                            TextField("Enter Amount (USD)", text: $amountText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding(.top, 5)
                    }

                    // ✅ Generate button
                    Button(action: generateKHQROffline) {
                        Text("Generate KHQR Offline")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)

                    // ✅ QR preview
                    if let qrImage = qrImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250, height: 250)
                            .padding(.top, 20)

                        Text("KHQR Payload:")
                            .font(.headline)
                            .padding(.top, 10)

                        Text(khqrString)
                            .font(.system(size: 12))
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .textSelection(.enabled)

                        Button(action: saveLocally) {
                            Text("Save QR Payload Locally")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.green)
                                .cornerRadius(10)
                        }
                        .padding(.top, 10)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
            .onAppear {
                restoreLastSaved()
            }
        }
    }

    // MARK: - ✅ Expiration timestamp helper (Offline)
    // ✅ MUST be 13-digit epoch milliseconds (based on SDK output in official docs)
    func expirationTimestampMillis(minutes: Int = 10) -> NSNumber {
        let expireDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        let millis = Int64(expireDate.timeIntervalSince1970 * 1000)
        return NSNumber(value: millis)
    }

    // MARK: - ✅ Main function: Generate KHQR Offline
    func generateKHQROffline() {

        errorMessage = ""

        guard let amount = Double(amountText), amount > 0 else {
            errorMessage = "Invalid amount. Please enter amount > 0"
            return
        }

        // ✅ expiration timestamp required by SDK (13-digit millis)
        let expireTime = expirationTimestampMillis(minutes: 10)
        
        let info = IndividualInfo(
            accountId: "khqr@ababank",
            merchantName: storeName,
            accountInformation: accountInfo,
            acquiringBank: "ABA Bank",
            currency: .Usd,
            amount: amount
        )

        // ✅ Required by your SDK
        info?.expirationTimestamp = expireTime

        let khqrResponse = BakongKHQR.generateIndividual(info!)

        if khqrResponse.status?.code == 0 {
            let khqrData = khqrResponse.data as? KHQRData
            khqrString = khqrData?.qr ?? ""
            qrImage = generateQRCode(from: khqrString)
            
        } else {
            errorMessage = "Error generating KHQR: \(khqrResponse.status?.message ?? "Unknown error")"
            qrImage = nil
            khqrString = ""
        }
    }
    
//ort te bong
    // MARK: - ✅ Generate QR Image locally
    func generateQRCode(from string: String) -> UIImage? {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
            if let cgimg = context.createCGImage(scaled, from: scaled.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        return nil
    }

    // MARK: - ✅ Save payload locally
    func saveLocally() {
        UserDefaults.standard.set(khqrString, forKey: "last_khqr_payload")
        print("Saved KHQR payload locally")
    }

    // MARK: - ✅ Restore last saved payload
    func restoreLastSaved() {
        if let saved = UserDefaults.standard.string(forKey: "last_khqr_payload"),
           !saved.isEmpty {
            khqrString = saved
            qrImage = generateQRCode(from: saved)
        }
    }
}

#Preview {
    ContentView()
}



/*
 Now it works well and to be improve more on dynamic bank
 
 */
