import Foundation

// MARK: - Commission Line Item

struct CommissionLineItem: Identifiable {
    let id = UUID()
    let jobId: Int
    let customerName: String
    let itemSoldDescription: String
    let saleAmount: Double
    let payoutAmount: Double
    let rateApplied: Double
    let typeTag: CommissionTypeTag
    let explanation: String
}

// MARK: - Week Pay Summary

struct WeekPaySummary {
    let weekYear: Int
    let weekOfYear: Int
    let weekStartDate: Date
    let weekEndDate: Date
    let label: String
    let isCurrentWeek: Bool

    let totalWeekVolume: Double
    let totalWeekCommission: Double
    let soldJobsCommission: Double
    let completedCarryoverCommission: Double
    let sameWeekSoldAndCompletedCommission: Double
    let unitSalesCommission: Double

    let lineItems: [CommissionLineItem]
}

// MARK: - Lifetime Metrics

struct LifetimeMetrics {
    var totalSalesVolume: Double = 0
    var totalCommissionEarned: Double = 0
    var pendingPipelineCommission: Double = 0
    var totalGrossProfit: Double = 0
    var grossMarginPercent: Double = 0
    var totalJobsCount: Int = 0
    var completedJobsCount: Int = 0
    var pendingJobsCount: Int = 0
    var unitSalesCount: Int = 0
}

// MARK: - Commission Engine

enum CommissionEngine {

    static func getWeekBounds(year: Int, weekOfYear: Int) -> (Date, Date) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current

        var components = DateComponents()
        components.year = year
        components.weekOfYear = weekOfYear
        components.weekday = 1  // Sunday = first day
        components.hour = 0
        components.minute = 0
        components.second = 0

        guard let start = cal.date(from: components) else {
            return (Date(), Date())
        }

        var endComponents = DateComponents()
        endComponents.day = 6
        let endOfDay = cal.date(byAdding: endComponents, to: start) ?? start
        var endCal = Calendar.current
        let endOfEndDay = cal.date(bySettingHour: 23, minute: 59, second: 59, of: endOfDay) ?? endOfDay

        return (start, endOfEndDay)
    }

    static func isSameWeek(_ timestamp1: Double, _ timestamp2: Double) -> Bool {
        let cal = Calendar.current
        let date1 = Date(timeIntervalSince1970: timestamp1 / 1000)
        let date2 = Date(timeIntervalSince1970: timestamp2 / 1000)
        let comp1 = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date1)
        let comp2 = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date2)
        return comp1.yearForWeekOfYear == comp2.yearForWeekOfYear &&
               comp1.weekOfYear == comp2.weekOfYear
    }

    static func calculateWeekSummary(year: Int, weekOfYear: Int, allJobs: [HvacJob]) -> WeekPaySummary {
        let (weekStart, weekEnd) = getWeekBounds(year: year, weekOfYear: weekOfYear)
        let now = Date()
        let currentCal = Calendar.current
        let isCurrentWeek = currentCal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now).yearForWeekOfYear == year &&
                            currentCal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now).weekOfYear == weekOfYear

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        dateFormatter.locale = Locale(identifier: "en_US")
        let label = "\(dateFormatter.string(from: weekStart)) - \(dateFormatter.string(from: weekEnd))"

        var lineItems: [CommissionLineItem] = []
        var totalVolume: Double = 0
        var soldJobsCommission: Double = 0
        var completedCarryoverCommission: Double = 0
        var sameWeekCommission: Double = 0
        var unitSalesCommission: Double = 0

        let itemDateFmt = DateFormatter()
        itemDateFmt.dateFormat = "MMM d, yyyy"
        itemDateFmt.locale = Locale(identifier: "en_US")

        for job in allJobs {
            let soldDate = Date(timeIntervalSince1970: job.soldDate / 1000)
            let soldInThisWeek = soldDate >= weekStart && soldDate <= weekEnd
            var completedInThisWeek = false
            if let compTs = job.completedDate {
                let compDate = Date(timeIntervalSince1970: compTs / 1000)
                completedInThisWeek = compDate >= weekStart && compDate <= weekEnd
            }

            let pcpSpiff: Double = (soldInThisWeek && job.isPcpSold) ? 25.0 : 0.0
            let pcpNote = pcpSpiff > 0 ? " + $25 PCP Spiff" : ""
            let soldDateStr = itemDateFmt.string(from: soldDate)
            let compDateStr = job.completedDate != nil ? itemDateFmt.string(from: Date(timeIntervalSince1970: job.completedDate! / 1000)) : "Pending"

            if job.jobType == .unitSale {
                if soldInThisWeek {
                    let payout = (job.saleAmount * (job.commissionRate / 100.0)) + pcpSpiff
                    totalVolume += job.saleAmount
                    unitSalesCommission += payout
                    lineItems.append(CommissionLineItem(
                        jobId: job.id,
                        customerName: job.customerName,
                        itemSoldDescription: job.itemSoldDescription,
                        saleAmount: job.saleAmount,
                        payoutAmount: payout,
                        rateApplied: job.commissionRate,
                        typeTag: .unitSale,
                        explanation: "Rule 2(a): Sold on \(soldDateStr) • Unit Sale flat \(job.commissionRate)% commission\(pcpNote)"
                    ))
                }
            } else {
                let baseRate = job.commissionRate
                let halfRate = baseRate / 2.0

                if soldInThisWeek && completedInThisWeek {
                    let payout = (job.saleAmount * (baseRate / 100.0)) + pcpSpiff
                    totalVolume += job.saleAmount
                    sameWeekCommission += payout
                    lineItems.append(CommissionLineItem(
                        jobId: job.id,
                        customerName: job.customerName,
                        itemSoldDescription: job.itemSoldDescription,
                        saleAmount: job.saleAmount,
                        payoutAmount: payout,
                        rateApplied: baseRate,
                        typeTag: .sameWeekFull,
                        explanation: "Rule 1(d): Sold & Installed on \(soldDateStr) (Full \(baseRate)% commission)\(pcpNote)"
                    ))
                } else if soldInThisWeek && !completedInThisWeek {
                    let payout = (job.saleAmount * (halfRate / 100.0)) + pcpSpiff
                    totalVolume += job.saleAmount
                    soldJobsCommission += payout
                    lineItems.append(CommissionLineItem(
                        jobId: job.id,
                        customerName: job.customerName,
                        itemSoldDescription: job.itemSoldDescription,
                        saleAmount: job.saleAmount,
                        payoutAmount: payout,
                        rateApplied: halfRate,
                        typeTag: .soldOnlyThisWeek,
                        explanation: "Rule 1(b): Sold on \(soldDateStr), pending install (\(halfRate)% advance)\(pcpNote)"
                    ))
                } else if !soldInThisWeek && completedInThisWeek {
                    let payout = job.saleAmount * (halfRate / 100.0)
                    completedCarryoverCommission += payout
                    lineItems.append(CommissionLineItem(
                        jobId: job.id,
                        customerName: job.customerName,
                        itemSoldDescription: job.itemSoldDescription,
                        saleAmount: job.saleAmount,
                        payoutAmount: payout,
                        rateApplied: halfRate,
                        typeTag: .completedCarryover,
                        explanation: "Rule 1(c): Installed on \(compDateStr) (\(halfRate)% final balance on \(soldDateStr) sale)"
                    ))
                }
            }
        }

        let totalCommission = soldJobsCommission + completedCarryoverCommission + sameWeekCommission + unitSalesCommission

        return WeekPaySummary(
            weekYear: year,
            weekOfYear: weekOfYear,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            label: label,
            isCurrentWeek: isCurrentWeek,
            totalWeekVolume: totalVolume,
            totalWeekCommission: totalCommission,
            soldJobsCommission: soldJobsCommission,
            completedCarryoverCommission: completedCarryoverCommission,
            sameWeekSoldAndCompletedCommission: sameWeekCommission,
            unitSalesCommission: unitSalesCommission,
            lineItems: lineItems
        )
    }

    static func calculateLifetimeMetrics(allJobs: [HvacJob]) -> LifetimeMetrics {
        var totalVolume: Double = 0
        var totalCommission: Double = 0
        var pendingPipeline: Double = 0
        var totalCost: Double = 0
        var completedCount = 0
        var pendingCount = 0
        var unitCount = 0

        for job in allJobs {
            totalVolume += job.saleAmount
            totalCommission += job.totalCommissionEarnedSoFar
            pendingPipeline += job.pendingCompletionBalance
            totalCost += job.totalAssociatedCost

            if job.jobType == .unitSale { unitCount += 1 }
            if job.isCompleted { completedCount += 1 } else { pendingCount += 1 }
        }

        let grossProfit = totalVolume - totalCost
        let grossMarginPercent = totalVolume > 0 ? (grossProfit / totalVolume) * 100.0 : 0.0

        return LifetimeMetrics(
            totalSalesVolume: totalVolume,
            totalCommissionEarned: totalCommission,
            pendingPipelineCommission: pendingPipeline,
            totalGrossProfit: grossProfit,
            grossMarginPercent: grossMarginPercent,
            totalJobsCount: allJobs.count,
            completedJobsCount: completedCount,
            pendingJobsCount: pendingCount,
            unitSalesCount: unitCount
        )
    }
}
