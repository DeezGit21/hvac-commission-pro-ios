import SwiftUI
import SwiftData

struct PayReportScreen: View {
    @ObservedObject var viewModel: HvacViewModel
    @Binding var currentScreen: AppScreen

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                let summary = viewModel.selectedWeekPaySummary

                // Pay Period Summary Card
                BentoCard(backgroundColor: .darkSurfaceElevated, borderColor: .goldCommission.opacity(0.5), borderWidth: 1.5) {
                    Text("PAY PERIOD SUMMARY")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.goldCommission)
                        .tracking(1)
                    Spacer().frame(height: 4)
                    Text(summary.label)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Text("Week #\(summary.weekOfYear), \(summary.weekYear)")
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)

                    Spacer().frame(height: 14)
                    Divider().background(Color.dividerColor)
                    Spacer().frame(height: 14)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("Total Sales Volume")
                                .font(.system(size: 13))
                                .foregroundColor(.textSecondary)
                            Text(formatMoney(summary.totalWeekVolume))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.textPrimary)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Net Commission Earned")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.goldCommission)
                            Text(formatMoney(summary.totalWeekCommission))
                                .font(.system(size: 22, weight: .black))
                                .foregroundColor(.goldCommission)
                        }
                    }
                }

                // Earnings Breakdown
                BentoCard(backgroundColor: .darkSurface) {
                    Text("EARNINGS BREAKDOWN BY RULE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.cyanAccent)
                        .tracking(1)
                    Spacer().frame(height: 10)

                    SummaryRow(title: "1(b) In-Progress Sold This Week (10%)", value: formatMoney(summary.soldJobsCommission), color: .cyanAccent)
                    SummaryRow(title: "1(c) Completed Carryover (10%)", value: formatMoney(summary.completedCarryoverCommission), color: .emeraldCompleted)
                    SummaryRow(title: "1(d) Same-Week Sold & Completed (20%)", value: formatMoney(summary.sameWeekSoldAndCompletedCommission), color: .goldCommission)
                    if summary.unitSalesCommission > 0 {
                        SummaryRow(title: "2(a) Unit Sales (10% Flat)", value: formatMoney(summary.unitSalesCommission), color: .orangeFlame)
                    }
                }

                // Itemized Line Items
                Text("ITEMIZED COMMISSION LINE ITEMS (\(summary.lineItems.count))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.textSecondary)
                    .tracking(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if summary.lineItems.isEmpty {
                    BentoCard(backgroundColor: .darkSurface) {
                        Text("No commission events occurred during this week.")
                            .font(.system(size: 14))
                            .foregroundColor(.textMuted)
                    }
                } else {
                    ForEach(summary.lineItems) { item in
                        BentoCard(backgroundColor: .darkSurface, onClick: {
                            if let job = viewModel.allJobs.first(where: { $0.id == item.jobId }) {
                                currentScreen = .jobEditor(job)
                            }
                        }) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    Text(item.customerName)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.textPrimary)
                                    Text(item.itemSoldDescription)
                                        .font(.system(size: 13))
                                        .foregroundColor(.textSecondary)
                                    Spacer().frame(height: 4)
                                    CommissionTypeBadge(typeTag: item.typeTag)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(formatMoney(item.payoutAmount))
                                        .font(.system(size: 16, weight: .black))
                                        .foregroundColor(.goldCommission)
                                    Text("Rate: \(String(format: "%.1f%%", item.rateApplied))")
                                        .font(.system(size: 11))
                                        .foregroundColor(.textMuted)
                                }
                            }
                            Spacer().frame(height: 6)
                            Text(item.explanation)
                                .font(.system(size: 11))
                                .foregroundColor(.cyanAccent)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .background(Color.darkBg.ignoresSafeArea())
        .navigationTitle("Weekly Pay Period Statement")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") { currentScreen = .dashboard }
                    .foregroundColor(.textPrimary)
            }
        }
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}
