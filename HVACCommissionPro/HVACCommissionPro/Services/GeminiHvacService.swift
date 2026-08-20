import Foundation
import UIKit

class GeminiHvacService {

    private let apiKey: String = {
        // Read from environment or Info.plist
        if let key = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !key.isEmpty, key != "MY_GEMINI_API_KEY" {
            return key
        }
        if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
           let key = dict["GEMINI_API_KEY"] as? String, !key.isEmpty, key != "MY_GEMINI_API_KEY" {
            return key
        }
        return ""
    }()

    var isConfigured: Bool {
        !apiKey.isEmpty && apiKey != "MY_GEMINI_API_KEY"
    }

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 90
        return URLSession(configuration: config)
    }()

    // MARK: - Analyze HVAC Diagnostics

    func analyzeHvacDiagnostics(input: DiagnosticInput) async throws -> DiagnosticResult {
        // Step 1: Check for missing essential parameters
        var missing: [String] = []
        if input.suctionPressurePsig.isEmpty { missing.append("Suction Pressure (psig)") }
        if input.vaporLineTempF.isEmpty { missing.append("Vapor Line Temperature (°F)") }
        if input.liquidPressurePsig.isEmpty { missing.append("Liquid Head Pressure (psig)") }
        if input.liquidLineTempF.isEmpty { missing.append("Liquid Line Temperature (°F)") }
        if input.returnAirTempF.isEmpty { missing.append("Return Air Temperature (°F)") }
        if input.supplyAirTempF.isEmpty { missing.append("Supply Air Temperature (°F)") }

        if !missing.isEmpty {
            return DiagnosticResult(
                isDataComplete: false,
                missingFields: missing,
                primaryFaultDiagnosis: "Incomplete Telemetry",
                technicalReport: "SYSTEMATIC DIAGNOSTIC PAUSED: Cannot formulate a definitive technical diagnosis based on incomplete physical data. Please measure and record: \(missing.joined(separator: ", ")). Making assumptions without these readings violates proper fault isolation protocol.",
                salesProposalSummary: "Pending complete system telemetry before finalizing system remediation and estimate."
            )
        }

        guard isConfigured else {
            return generateLocalDiagnostic(input: input)
        }

        let prompt = buildDiagnosticPrompt(input: input)

        do {
            let raw = try await callGeminiText(prompt: prompt)
            let jsonString = extractJsonSubstring(raw)
            if let data = jsonString.data(using: .utf8),
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {

                return DiagnosticResult(
                    isDataComplete: true,
                    missingFields: [],
                    primaryFaultDiagnosis: (json["primary_fault"] as? String) ?? "Systematic HVAC Fault Isolated",
                    technicalReport: (json["technical_report"] as? String) ?? raw,
                    salesProposalSummary: (json["sales_proposal_summary"] as? String) ?? ""
                )
            } else {
                return generateLocalDiagnostic(input: input)
            }
        } catch {
            return generateLocalDiagnostic(input: input)
        }
    }

    // MARK: - Analyze Image for Job Data

    func analyzeImageForJobData(image: UIImage) async throws -> ScannedJobData {
        guard isConfigured else {
            return ScannedJobData(
                customerName: "Scanned Customer",
                installationAddress: "Scanned Job Site",
                itemSoldDescription: "HVAC Equipment Replacement",
                equipmentDetails: "Carrier 16 SEER2 (M/N: 24ABC6, S/N: 2419E981)",
                saleAmount: 12500.0,
                equipmentCost: 4800.0,
                laborCost: 1600.0,
                notes: "Scanned locally. Configure GEMINI_API_KEY for live OCR extraction."
            )
        }

        let prompt = """
        You are an expert HVAC Technician and Data OCR Specialist.
        Analyze this photo of an HVAC equipment rating plate, estimate, invoice, or work order.
        Extract all legible specifications and financial numbers.
        Return ONLY valid JSON matching this schema:
        {
           "customerName": "...",
           "installationAddress": "...",
           "itemSoldDescription": "...",
           "equipmentDetails": "Model: ... Serial: ... Electrical RLA: ...",
           "saleAmount": 12500.00,
           "equipmentCost": 4500.00,
           "laborCost": 1500.00,
           "notes": "..."
        }
        """

        do {
            let raw = try await callGeminiMultimodal(prompt: prompt, image: image)
            let jsonString = extractJsonSubstring(raw)
            if let data = jsonString.data(using: .utf8),
               let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {

                return ScannedJobData(
                    customerName: (json["customerName"] as? String) ?? "",
                    customerAddress: (json["installationAddress"] as? String) ?? "",
                    installationAddress: (json["installationAddress"] as? String) ?? "",
                    itemSoldDescription: (json["itemSoldDescription"] as? String) ?? "",
                    equipmentDetails: (json["equipmentDetails"] as? String) ?? "",
                    saleAmount: (json["saleAmount"] as? Double) ?? 0,
                    equipmentCost: (json["equipmentCost"] as? Double) ?? 0,
                    laborCost: (json["laborCost"] as? Double) ?? 0,
                    notes: (json["notes"] as? String) ?? ""
                )
            } else {
                return ScannedJobData(itemSoldDescription: "Scanned Equipment", notes: "Error processing image response")
            }
        } catch {
            return ScannedJobData(itemSoldDescription: "Scanned Equipment", notes: "Error processing image: \(error.localizedDescription)")
        }
    }

    // MARK: - Private: Prompt Builder

    private func buildDiagnosticPrompt(input: DiagnosticInput) -> String {
        var s = "You are an expert master HVAC Diagnostic Technician and Estimate / Invoice technical writing expert.\n"
        s += "Systematic Diagnostic Context:\n"
        s += "System Type: \(input.systemType) | Refrigerant: \(input.refrigerantType) | Metering: \(input.meteringDevice)\n"
        s += "Suction Pressure: \(input.suctionPressurePsig) psig | Vapor Line Temp: \(input.vaporLineTempF) °F\n"
        s += "Liquid Pressure: \(input.liquidPressurePsig) psig | Liquid Line Temp: \(input.liquidLineTempF) °F\n"
        s += "Return Air: \(input.returnAirTempF) °F | Supply Air: \(input.supplyAirTempF) °F (Target Subcooling: \(input.targetSubcoolingF)°F, Target Superheat: \(input.targetSuperheatF)°F)\n"
        if !input.supplyStaticPressure.isEmpty || !input.returnStaticPressure.isEmpty {
            s += "Static Pressures: Supply = \(input.supplyStaticPressure) in w.c., Return = \(input.returnStaticPressure) in w.c.\n"
        }
        if !input.compressorAmps.isEmpty {
            s += "Compressor Amp Draw: \(input.compressorAmps)A (Rated RLA: \(input.ratedCompressorRla)A)\n"
        }
        if !input.capacitorActualUf.isEmpty {
            s += "Capacitor: Measured \(input.capacitorActualUf)uF / Rated \(input.capacitorRatingUf)uF\n"
        }
        s += "Customer Complaint: \(input.customerComplaint)\n"
        s += "Equipment Age: \(input.unitAgeYears) years | Model: \(input.systemModelNumber) | S/N: \(input.systemSerialNumber)\n\n"
        s += "MANDATORY RULES:\n"
        s += "1. Generated reports and outputs ALWAYS maintain a first-person, professional technical tone ('I measured...', 'I evaluated...', 'I isolated...').\n"
        s += "2. Use standard HVAC terminology (superheat, subcooling, amp draw, static pressure, delta T, saturation temperature, non-condensables, metering restriction).\n"
        s += "3. Provide two distinct sections formatted strictly as JSON:\n"
        s += "   - 'primary_fault': Short 3-7 word diagnosis\n"
        s += "   - 'technical_report': First-person, exhaustive diagnostic report explaining superheat, subcooling, delta T, and fault isolation logic.\n"
        s += "   - 'sales_proposal_summary': Highly effective, value-focused recommendation and estimate summary to help close the sale.\n\n"
        s += #"JSON Output Format: {"primary_fault": "...", "technical_report": "...", "sales_proposal_summary": "..."}"#
        return s
    }

    // MARK: - Private: Local Diagnostic Fallback

    private func generateLocalDiagnostic(input: DiagnosticInput) -> DiagnosticResult {
        let suctionP = Double(input.suctionPressurePsig) ?? 0
        let vaporT = Double(input.vaporLineTempF) ?? 0
        let liquidP = Double(input.liquidPressurePsig) ?? 0
        let liquidT = Double(input.liquidLineTempF) ?? 0
        let returnT = Double(input.returnAirTempF) ?? 0
        let supplyT = Double(input.supplyAirTempF) ?? 0

        let refrigerant = Refrigerant(rawValue: input.refrigerantType.replacingOccurrences(of: " (Puron)", with: "")) ?? .r410a

        let superheat = HvacPhysicsCalculator.calculateSuperheat(
            suctionPressurePsig: suctionP, suctionLineTempF: vaporT, refrigerant: refrigerant
        )
        let subcooling = HvacPhysicsCalculator.calculateSubcooling(
            liquidPressurePsig: liquidP, liquidLineTempF: liquidT, refrigerant: refrigerant
        )
        let deltaT = HvacPhysicsCalculator.calculateDeltaT(returnAirTempF: returnT, supplyAirTempF: supplyT)

        var fault = "Systematic HVAC Fault Isolated"
        var report = "I evaluated the system readings and calculated the following:\n"
        report += "Superheat: \(String(format: "%.1f", superheat))°F (Target: \(input.targetSuperheatF)°F)\n"
        report += "Subcooling: \(String(format: "%.1f", subcooling))°F (Target: \(input.targetSubcoolingF)°F)\n"
        report += "Delta T: \(String(format: "%.1f", deltaT))°F\n\n"

        if superheat > 25 {
            fault = "Low Charge / Undercharged System"
            report += "I observed an abnormally high superheat reading of \(String(format: "%.1f", superheat))°F, which exceeds the acceptable range. This indicates an insufficient refrigerant charge or a metering device restriction. I recommend recovering, evacuating, and recharging the system to manufacturer specifications."
        } else if subcooling > 20 {
            fault = "Overcharged System / Restricted Liquid Line"
            report += "I measured subcooling at \(String(format: "%.1f", subcooling))°F, significantly above the target of \(input.targetSubcoolingF)°F. This suggests an overcharged system or a restriction in the liquid line. I recommend reclaiming excess refrigerant and verifying proper metering device operation."
        } else if deltaT < 15 {
            fault = "Low Airflow / Dirty Coil"
            report += "I measured a delta T of only \(String(format: "%.1f", deltaT))°F, which is below the optimal 16-22°F range. This indicates a possible airflow issue, dirty evaporator coil, or blower motor degradation. I recommend inspecting and cleaning the evaporator coil, replacing filters, and verifying proper CFM."
        } else {
            fault = "System Operating Within Normal Parameters"
            report += "All measured values are within acceptable ranges. Superheat, subcooling, and delta T are all within specification. I recommend maintaining the current system and scheduling routine preventive maintenance."
        }

        let sales = "Based on my diagnostic findings (\(fault)), I recommend scheduling the necessary remediation work at the customer's earliest convenience. Estimated investment varies based on parts and labor requirements."

        return DiagnosticResult(
            isDataComplete: true,
            missingFields: [],
            primaryFaultDiagnosis: fault,
            technicalReport: report,
            salesProposalSummary: sales
        )
    }

    // MARK: - Private: Gemini API Calls

    private func callGeminiText(prompt: String) async throws -> String {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [[
                "parts": [["text": prompt]]
            ]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw URLError(.cannotDecodeContentData)
        }
        return text
    }

    private func callGeminiMultimodal(prompt: String, image: UIImage) async throws -> String {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw URLError(.cannotEncodeContentData)
        }
        let base64 = imageData.base64EncodedString()

        let body: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": prompt],
                    ["inline_data": ["mime_type": "image/jpeg", "data": base64]]
                ]
            ]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw URLError(.cannotDecodeContentData)
        }
        return text
    }

    private func extractJsonSubstring(_ text: String) -> String {
        var startIndex = text.startIndex
        if let braceStart = text.firstIndex(of: "{") {
            startIndex = braceStart
        }
        var endIndex = text.endIndex
        if let braceEnd = text.lastIndex(of: "}") {
            endIndex = text.index(after: braceEnd)
        }
        return String(text[startIndex..<endIndex])
    }
}
