import SwiftUI

struct DiagnosticScreen: View {
    @ObservedObject var viewModel: HvacViewModel
    @Binding var currentScreen: AppScreen

    @State private var refrigerantText: String = "R410A"
    @State private var meteringDevice: String = "TXV"
    @State private var suctionPressureText: String = ""
    @State private var liquidPressureText: String = ""
    @State private var vaporLineTempText: String = ""
    @State private var liquidLineTempText: String = ""
    @State private var returnAirTempText: String = ""
    @State private var supplyAirTempText: String = ""
    @State private var compressorAmpsText: String = ""
    @State private var ratedCompressorRlaText: String = ""
    @State private var unitAgeYearsText: String = ""
    @State private var customerComplaints: String = ""

    private var refrigerant: Refrigerant {
        Refrigerant(rawValue: refrigerantText) ?? .r410a
    }

    private var suctionPressure: Double { Double(suctionPressureText) ?? 0 }
    private var liquidPressure: Double { Double(liquidPressureText) ?? 0 }
    private var vaporLineTemp: Double { Double(vaporLineTempText) ?? 0 }
    private var liquidLineTemp: Double { Double(liquidLineTempText) ?? 0 }
    private var returnTemp: Double { Double(returnAirTempText) ?? 0 }
    private var supplyTemp: Double { Double(supplyAirTempText) ?? 0 }
    private var supplyStatic: Double { 0 }
    private var returnStatic: Double { 0 }

    private var superheat: Double? {
        guard suctionPressure > 0 && vaporLineTemp > 0 else { return nil }
        return HvacPhysicsCalculator.calculateSuperheat(suctionPressurePsig: suctionPressure, suctionLineTempF: vaporLineTemp, refrigerant: refrigerant)
    }

    private var subcooling: Double? {
        guard liquidPressure > 0 && liquidLineTemp > 0 else { return nil }
        return HvacPhysicsCalculator.calculateSubcooling(liquidPressurePsig: liquidPressure, liquidLineTempF: liquidLineTemp, refrigerant: refrigerant)
    }

    private var deltaT: Double? {
        guard returnTemp > 0 && supplyTemp > 0 else { return nil }
        return HvacPhysicsCalculator.calculateDeltaT(returnAirTempF: returnTemp, supplyAirTempF: supplyTemp)
    }

    private var tesp: Double {
        HvacPhysicsCalculator.calculateTESP(supplyStaticInWc: supplyStatic, returnStaticInWc: returnStatic)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Telemetry Mini Boxes
                BentoCard(backgroundColor: .darkSurfaceElevated, borderColor: .cyanAccent.opacity(0.4), borderWidth: 1.5) {
                    Text("CALCULATED REFRIGERATION & AIRFLOW TELEMETRY")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.cyanAccent)
                        .tracking(1)
                    Spacer().frame(height: 10)

                    HStack(spacing: 8) {
                        TelemetryMiniBox(title: "Superheat", value: superheat != nil ? String(format: "%.1f°F", superheat!) : "--", evaluation: superheat != nil ? (superheat! >= 8 && superheat! <= 18 ? "Normal" : "Abnormal") : "", isNormal: superheat != nil && superheat! >= 8 && superheat! <= 18)
                        TelemetryMiniBox(title: "Subcooling", value: subcooling != nil ? String(format: "%.1f°F", subcooling!) : "--", evaluation: subcooling != nil ? (subcooling! >= 8 && subcooling! <= 14 ? "Normal" : "Abnormal") : "", isNormal: subcooling != nil && subcooling! >= 8 && subcooling! <= 14)
                        TelemetryMiniBox(title: "Delta T", value: deltaT != nil ? String(format: "%.1f°F", deltaT!) : "--", evaluation: deltaT != nil ? (deltaT! >= 16 && deltaT! <= 22 ? "Optimal" : "Low") : "", isNormal: deltaT != nil && deltaT! >= 16 && deltaT! <= 22)
                        TelemetryMiniBox(title: "TESP", value: String(format: "%.2f\"", tesp), evaluation: tesp <= 0.50 ? "Acceptable" : "High Static", isNormal: tesp <= 0.50)
                    }
                }

                // Refrigerant & System Specs
                BentoCard(backgroundColor: .darkSurface) {
                    Text("REFRIGERANT TYPE & SYSTEM SPECS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.textSecondary)
                        .tracking(1)
                    Spacer().frame(height: 10)

                    // Refrigerant selector
                    HStack(spacing: 8) {
                        ForEach(Refrigerant.allCases, id: \.self) { ref in
                            let isSelected = refrigerantText == ref.rawValue
                            Text(ref.rawValue)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(isSelected ? .darkBg : .textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(isSelected ? Color.orangeFlame : Color.darkBg)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture { refrigerantText = ref.rawValue }
                        }
                    }

                    Spacer().frame(height: 12)

                    HStack(spacing: 10) {
                        StyledTextField(title: "Suction (psig) *", text: $suctionPressureText, keyboardType: .decimalPad)
                        StyledTextField(title: "Liquid (psig) *", text: $liquidPressureText, keyboardType: .decimalPad)
                    }

                    Spacer().frame(height: 10)

                    HStack(spacing: 10) {
                        StyledTextField(title: "Vapor Line (°F) *", text: $vaporLineTempText, keyboardType: .decimalPad)
                        StyledTextField(title: "Liquid Line (°F) *", text: $liquidLineTempText, keyboardType: .decimalPad)
                    }
                }

                // Airflow & Electrical
                BentoCard(backgroundColor: .darkSurface) {
                    Text("AIRFLOW, ELECTRICAL & COMPLAINT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.textSecondary)
                        .tracking(1)
                    Spacer().frame(height: 10)

                    HStack(spacing: 10) {
                        StyledTextField(title: "Return Air (°F) *", text: $returnAirTempText, keyboardType: .decimalPad)
                        StyledTextField(title: "Supply Air (°F) *", text: $supplyAirTempText, keyboardType: .decimalPad)
                    }

                    Spacer().frame(height: 10)

                    HStack(spacing: 10) {
                        StyledTextField(title: "Comp Amps (A)", text: $compressorAmpsText, keyboardType: .decimalPad)
                        StyledTextField(title: "Rated RLA (A)", text: $ratedCompressorRlaText, keyboardType: .decimalPad)
                    }

                    Spacer().frame(height: 10)

                    HStack(spacing: 10) {
                        StyledTextField(title: "System Age (Years)", text: $unitAgeYearsText, keyboardType: .numberPad)
                        StyledTextField(title: "Metering Device", text: $meteringDevice)
                    }

                    Spacer().frame(height: 10)

                    StyledTextField(title: "Customer Complaint / Symptoms", text: $customerComplaints)
                }

                // Run Diagnostic Button
                Button {
                    let input = DiagnosticInput(
                        refrigerantType: refrigerantText,
                        meteringDevice: meteringDevice,
                        suctionPressurePsig: suctionPressureText,
                        vaporLineTempF: vaporLineTempText,
                        liquidPressurePsig: liquidPressureText,
                        liquidLineTempF: liquidLineTempText,
                        returnAirTempF: returnAirTempText,
                        supplyAirTempF: supplyAirTempText,
                        compressorAmps: compressorAmpsText,
                        ratedCompressorRla: ratedCompressorRlaText,
                        customerComplaint: customerComplaints,
                        unitAgeYears: unitAgeYearsText
                    )
                    viewModel.runDiagnostic(input: input)
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.darkBg)
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "brain.head.profile")
                        }
                        Text(isLoading ? "Analyzing Thermodynamics..." : "Generate Diagnostic & Sales Proposal")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(canRun ? Color.orangeFlame : Color.darkSurface)
                    .foregroundColor(.darkBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isLoading)

                // Results
                switch viewModel.diagnosticState {
                case .success(let result):
                    BentoCard(backgroundColor: .darkSurfaceElevated, borderColor: result.isDataComplete ? Color.emeraldCompleted.opacity(0.6) : Color.orangeFlame.opacity(0.6), borderWidth: 1.5) {
                        HStack {
                            Text("FIRST-PERSON FIELD DIAGNOSTIC REPORT")
                                .font(.system(size: 14, weight: .black))
                                .foregroundColor(result.isDataComplete ? .emeraldCompleted : .orangeFlame)
                            Spacer()
                            Text(result.isDataComplete ? "VERIFIED" : "INCOMPLETE")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(result.isDataComplete ? .emeraldCompleted : .orangeFlame)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background((result.isDataComplete ? Color.emeraldCompleted : Color.orangeFlame).opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }

                        Spacer().frame(height: 10)
                        Text(result.primaryFaultDiagnosis)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.textPrimary)

                        Spacer().frame(height: 8)
                        Text(result.technicalReport)
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)

                        if !result.salesProposalSummary.isEmpty {
                            Spacer().frame(height: 12)
                            Divider().background(Color.dividerColor)
                            Spacer().frame(height: 12)
                            Text("SALES RECOMMENDATION & ESTIMATE CLOSING SUMMARY")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.goldCommission)
                            Spacer().frame(height: 6)
                            Text(result.salesProposalSummary)
                                .font(.system(size: 14))
                                .foregroundColor(.textPrimary)
                        }

                        if result.isDataComplete {
                            Spacer().frame(height: 14)
                            Button {
                                let readings = "Suction: \(suctionPressureText)psi, Liquid: \(liquidPressureText)psi, SH: \(superheat != nil ? String(format: "%.1f°F", superheat!) : "N/A"), SC: \(subcooling != nil ? String(format: "%.1f°F", subcooling!) : "N/A"), TESP: \(String(format: "%.2f\"", tesp))"
                                let prefilledJob = HvacJob(
                                    customerName: "",
                                    soldDate: Date().timeIntervalSince1970 * 1000,
                                    itemSoldDescription: result.primaryFaultDiagnosis.isEmpty ? "HVAC System Remediation & Replacement" : result.primaryFaultDiagnosis,
                                    saleAmount: 0,
                                    systemReadings: readings,
                                    salesProposalSummary: result.salesProposalSummary
                                )
                                currentScreen = .jobEditor(prefilledJob)
                            } label: {
                                HStack {
                                    Image(systemName: "cart.fill")
                                    Text("Convert into Sold Job Lead")
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.cyanAccent)
                                .foregroundColor(.darkBg)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }

                case .error(let message):
                    BentoCard(backgroundColor: .darkSurface, borderColor: .rosePending) {
                        Text("Diagnostic Error")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.rosePending)
                        Spacer().frame(height: 4)
                        Text(message)
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }

                default:
                    EmptyView()
                }
            }
            .padding(16)
            .padding(.bottom, 100)
        }
        .background(Color.darkBg.ignoresSafeArea())
        .navigationTitle("HVAC Diagnostics & Technical Writing")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") {
                    viewModel.clearDiagnosticState()
                    currentScreen = .dashboard
                }
                .foregroundColor(.textPrimary)
            }
        }
    }

    private var isLoading: Bool {
        if case .loading = viewModel.diagnosticState { return true }
        return false
    }

    private var canRun: Bool {
        !isLoading
    }
}
