import SwiftUI
import PhotosUI

struct ScanInvoiceScreen: View {
    @ObservedObject var viewModel: HvacViewModel
    @Binding var currentScreen: AppScreen

    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Info Card
                BentoCard(backgroundColor: .darkSurfaceElevated, borderColor: .cyanAccent.opacity(0.4), borderWidth: 1.5) {
                    Text("INTELLIGENT HVAC DATA EXTRACTION")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.cyanAccent)
                        .tracking(1)
                    Spacer().frame(height: 6)
                    Text("Scan equipment data plates, distributor invoices, or job estimates to instantly extract model/serial numbers, equipment costs, and customer details directly into your commission tracking ledger.")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                }

                // Photo Picker Button
                BentoCard(backgroundColor: .darkSurface, onClick: nil) {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(Color.cyanAccent.opacity(0.15))
                                    .frame(width: 64, height: 64)
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 28))
                                    .foregroundColor(.cyanAccent)
                            }
                            Text("Select Invoice or Rating Plate Photo")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.textPrimary)
                            Text("Supports JPEG, PNG, HEIC files")
                                .font(.system(size: 13))
                                .foregroundColor(.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                }

                // States
                switch viewModel.imageScanState {
                case .scanning:
                    BentoCard(backgroundColor: .darkSurface) {
                        HStack {
                            ProgressView()
                                .tint(.cyanAccent)
                            Spacer().frame(width: 12)
                            Text("Extracting HVAC Model, Serial & Cost Data...")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.textPrimary)
                        }
                    }

                case .success(let data):
                    let generatedJob = HvacJob(
                        customerName: data.customerName.isEmpty ? "Scanned Customer" : data.customerName,
                        soldDate: Date().timeIntervalSince1970 * 1000,
                        itemSoldDescription: data.itemSoldDescription.isEmpty ? "HVAC Equipment Replacement" : data.itemSoldDescription,
                        saleAmount: data.saleAmount,
                        installationAddress: data.installationAddress.isEmpty ? data.customerAddress : data.installationAddress,
                        equipmentDetails: data.equipmentDetails,
                        equipmentCost: data.equipmentCost,
                        laborCost: data.laborCost,
                        notes: data.notes
                    )

                    BentoCard(backgroundColor: .darkSurfaceElevated, borderColor: .emeraldCompleted.opacity(0.6), borderWidth: 1.5) {
                        Text("EXTRACTED HVAC CONTRACT DATA")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.emeraldCompleted)
                            .tracking(1)
                        Spacer().frame(height: 10)

                        ScannedRow(label: "Customer Name", value: generatedJob.customerName)
                        ScannedRow(label: "Item / System", value: generatedJob.itemSoldDescription)
                        if !generatedJob.installationAddress.isEmpty {
                            ScannedRow(label: "Address", value: generatedJob.installationAddress)
                        }
                        if !generatedJob.equipmentDetails.isEmpty {
                            ScannedRow(label: "Model / Serial Specs", value: generatedJob.equipmentDetails)
                        }
                        ScannedRow(label: "Sale Amount", value: formatMoney(generatedJob.saleAmount))
                        ScannedRow(label: "Equipment Cost", value: formatMoney(generatedJob.equipmentCost))
                        ScannedRow(label: "Labor Cost", value: formatMoney(generatedJob.laborCost))

                        Spacer().frame(height: 14)

                        Button {
                            currentScreen = .jobEditor(generatedJob)
                        } label: {
                            HStack {
                                Image(systemName: "checkmark")
                                Text("Open in Job Editor to Save")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.cyanAccent)
                            .foregroundColor(.darkBg)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }

                case .error(let message):
                    BentoCard(backgroundColor: .darkSurface, borderColor: .rosePending) {
                        Text("Scan Error")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.rosePending)
                        Spacer().frame(height: 4)
                        Text(message)
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }

                case .idle:
                    EmptyView()
                }
            }
            .padding(16)
            .padding(.bottom, 100)
        }
        .background(Color.darkBg.ignoresSafeArea())
        .navigationTitle("OCR Equipment & Invoice Scanner")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") {
                    viewModel.clearImageScanState()
                    currentScreen = .dashboard
                }
                .foregroundColor(.textPrimary)
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let item = newItem, let data = try? await item.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        selectedImage = uiImage
                        viewModel.scanImage(image: uiImage)
                    }
                }
            }
        }
    }
}
