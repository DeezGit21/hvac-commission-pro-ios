import Foundation
import SwiftData

enum JobType: String, Codable, CaseIterable {
    case standardJob = "STANDARD_JOB"
    case unitSale = "UNIT_SALE"
    case custom = "CUSTOM"

    var label: String {
        switch self {
        case .standardJob: return "Standard Job (20% Split)"
        case .unitSale: return "Unit Sale (10% Flat)"
        case .custom: return "Custom Rate"
        }
    }

    var defaultRatePercent: Double {
        switch self {
        case .standardJob: return 20.0
        case .unitSale: return 10.0
        case .custom: return 20.0
        }
    }

    var shortLabel: String {
        switch self {
        case .standardJob: return "Standard (20%)"
        case .unitSale: return "Unit Sale (10%)"
        case .custom: return "Custom Rate"
        }
    }
}

enum CommissionTypeTag: String, Codable {
    case soldOnlyThisWeek = "SOLD_ONLY_THIS_WEEK"
    case completedCarryover = "COMPLETED_CARRYOVER"
    case sameWeekFull = "SAME_WEEK_FULL"
    case unitSale = "UNIT_SALE"
    case customRate = "CUSTOM_RATE"

    var label: String {
        switch self {
        case .soldOnlyThisWeek: return "Sold (10% Advance)"
        case .completedCarryover: return "Completed (10% Final)"
        case .sameWeekFull: return "Sold & Done (20% Full)"
        case .unitSale: return "Unit Sale (10% Flat)"
        case .customRate: return "Custom Commission"
        }
    }
}

enum Refrigerant: String, Codable, CaseIterable {
    case r410a = "R410A"
    case r22 = "R22"
    case r32 = "R32"
    case r454b = "R454B"

    var displayName: String {
        switch self {
        case .r410a: return "R-410A"
        case .r22: return "R-22"
        case .r32: return "R-32"
        case .r454b: return "R-454B (A2L)"
        }
    }
}

@Model
final class HvacJob {
    var id: Int = 0

    // Core Customer & What Was Sold
    var customerName: String = ""
    var customerPhone: String = ""
    var soldDate: Double = 0
    var anticipatedCompletionDate: Double? = nil
    var completedDate: Double? = nil
    var isCompleted: Bool = false
    var itemSoldDescription: String = ""
    var jobTypeRaw: String = JobType.standardJob.rawValue

    // Financial & Commission values
    var saleAmount: Double = 0
    var commissionRate: Double = 20.0
    var isPcpSold: Bool = false

    // Detailed Tracking Fields
    var installationAddress: String = ""
    var equipmentDetails: String = ""
    var equipmentCost: Double = 0
    var laborCost: Double = 0
    var materialCost: Double = 0
    var permitCost: Double = 0

    // Technical Diagnostics & Service Proposal notes
    var notes: String = ""
    var systemReadings: String = ""
    var diagnosticSummary: String = ""
    var salesProposalSummary: String = ""

    var createdAt: Double = 0
    var updatedAt: Double = 0

    var jobType: JobType {
        get { JobType(rawValue: jobTypeRaw) ?? .standardJob }
        set { jobTypeRaw = newValue.rawValue }
    }

    init(
        id: Int = 0,
        customerName: String = "",
        customerPhone: String = "",
        soldDate: Double = Date().timeIntervalSince1970 * 1000,
        anticipatedCompletionDate: Double? = nil,
        completedDate: Double? = nil,
        isCompleted: Bool = false,
        itemSoldDescription: String = "",
        jobType: JobType = .standardJob,
        saleAmount: Double = 0,
        commissionRate: Double = 20.0,
        isPcpSold: Bool = false,
        installationAddress: String = "",
        equipmentDetails: String = "",
        equipmentCost: Double = 0,
        laborCost: Double = 0,
        materialCost: Double = 0,
        permitCost: Double = 0,
        notes: String = "",
        systemReadings: String = "",
        diagnosticSummary: String = "",
        salesProposalSummary: String = "",
        createdAt: Double = Date().timeIntervalSince1970 * 1000,
        updatedAt: Double = Date().timeIntervalSince1970 * 1000
    ) {
        self.id = id
        self.customerName = customerName
        self.customerPhone = customerPhone
        self.soldDate = soldDate
        self.anticipatedCompletionDate = anticipatedCompletionDate
        self.completedDate = completedDate
        self.isCompleted = isCompleted
        self.itemSoldDescription = itemSoldDescription
        self.jobTypeRaw = jobType.rawValue
        self.saleAmount = saleAmount
        self.commissionRate = commissionRate
        self.isPcpSold = isPcpSold
        self.installationAddress = installationAddress
        self.equipmentDetails = equipmentDetails
        self.equipmentCost = equipmentCost
        self.laborCost = laborCost
        self.materialCost = materialCost
        self.permitCost = permitCost
        self.notes = notes
        self.systemReadings = systemReadings
        self.diagnosticSummary = diagnosticSummary
        self.salesProposalSummary = salesProposalSummary
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties (mirrors Android HvacJob)

    var pcpSpiffAmount: Double {
        isPcpSold ? 25.0 : 0.0
    }

    var totalAssociatedCost: Double {
        equipmentCost + laborCost + materialCost + permitCost
    }

    var grossProfit: Double {
        saleAmount - totalAssociatedCost
    }

    var profitMarginPercent: Double {
        saleAmount > 0 ? (grossProfit / saleAmount) * 100.0 : 0.0
    }

    var totalPotentialCommission: Double {
        (saleAmount * (commissionRate / 100.0)) + pcpSpiffAmount
    }

    var soldCommissionEarned: Double {
        let base: Double
        switch jobType {
        case .standardJob: base = saleAmount * ((commissionRate / 2.0) / 100.0)
        case .unitSale: base = saleAmount * (commissionRate / 100.0)
        case .custom: base = saleAmount * ((commissionRate / 2.0) / 100.0)
        }
        return base + pcpSpiffAmount
    }

    var completionCommissionEarned: Double {
        guard isCompleted else { return 0.0 }
        switch jobType {
        case .standardJob: return saleAmount * ((commissionRate / 2.0) / 100.0)
        case .unitSale: return 0.0
        case .custom: return saleAmount * ((commissionRate / 2.0) / 100.0)
        }
    }

    var totalCommissionEarnedSoFar: Double {
        soldCommissionEarned + completionCommissionEarned
    }

    var pendingCompletionBalance: Double {
        guard !isCompleted && jobType != .unitSale else { return 0.0 }
        return saleAmount * ((commissionRate / 2.0) / 100.0)
    }

    // MARK: - Date Helpers

    func isAnticipatedToday() -> Bool {
        guard !isCompleted, let anticipated = anticipatedCompletionDate else { return false }
        return Calendar.current.isDateInToday(Date(timeIntervalSince1970: anticipated / 1000))
    }

    func isAnticipatedOverdue() -> Bool {
        guard !isCompleted, let anticipated = anticipatedCompletionDate else { return false }
        let today = Calendar.current.startOfDay(for: Date())
        let target = Date(timeIntervalSince1970: anticipated / 1000)
        return target < today
    }
}
