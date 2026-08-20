import Foundation

struct DiagnosticInput: Codable {
    var systemType: String = "Split Heat Pump"
    var refrigerantType: String = "R-410A (Puron)"
    var meteringDevice: String = "TXV"

    var suctionPressurePsig: String = ""
    var vaporLineTempF: String = ""
    var liquidPressurePsig: String = ""
    var liquidLineTempF: String = ""

    var returnAirTempF: String = ""
    var supplyAirTempF: String = ""
    var targetSubcoolingF: String = "10"
    var targetSuperheatF: String = "12"

    var supplyStaticPressure: String = ""
    var returnStaticPressure: String = ""

    var compressorAmps: String = ""
    var ratedCompressorRla: String = ""
    var blowerMotorAmps: String = ""
    var capacitorRatingUf: String = ""
    var capacitorActualUf: String = ""

    var customerComplaint: String = ""
    var unitAgeYears: String = ""
    var systemModelNumber: String = ""
    var systemSerialNumber: String = ""
}

struct DiagnosticResult: Codable {
    var isDataComplete: Bool
    var missingFields: [String]
    var primaryFaultDiagnosis: String
    var technicalReport: String
    var salesProposalSummary: String
}

struct ScannedJobData: Codable {
    var customerName: String = ""
    var customerAddress: String = ""
    var installationAddress: String = ""
    var itemSoldDescription: String = ""
    var equipmentDetails: String = ""
    var saleAmount: Double = 0
    var equipmentCost: Double = 0
    var laborCost: Double = 0
    var notes: String = ""
}
