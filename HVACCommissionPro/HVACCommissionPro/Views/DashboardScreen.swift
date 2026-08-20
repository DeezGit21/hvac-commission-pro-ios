import SwiftUI

struct DashboardScreen: View {
    @ObservedObject var viewModel: HvacViewModel
    @Binding var currentScreen: AppScreen

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                let summary = viewModel.selectedWeekPaySummary
                let metrics = viewModel.lifetimeMetrics
                let todaySuggestions = viewModel.jobsDueToday

                // Today's Completion Suggestions
                if !todaySuggestions.isEmpty {
                    BentoCard(backgroundColor: Color(red: 0.125, green: 0.090, blue: 0.039), borderColor: .orangeFlame, borderWidth: 1.5) {
                        VStack(spacing: 0) {
                            HStack {
                                HStack {
                                    Image(systemName: "bell.badge.fill")
                                        .foregroundColor(.orangeFlame)
                                        .font(.system(size: 20))
                                    Text("READY FOR COMPLETION TODAY (\(todaySuggestions.count))")
                                        .font(.system(size: 14, weight: .black))
                                        .foregroundColor(.orangeFlame)
                                        .tracking(0.5)
                                }
                                Spacer()
                                Text("View Pipeline")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.orangeFlame)
                                    .onTapGesture { currentScreen = .pendingJobs }
                            }

                            Text("These sold jobs are scheduled for install completion today. Tap to mark done and claim your final 10% commission!")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                                .padding(.top, 4)
                                .padding(.bottom, 10)

                            ForEach(todaySuggestions, id: \.id) { job in
                                BentoCard(backgroundColor: .darkSurface, onClick: {
                                    currentScreen = .jobEditor(job)
                                }) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(job.customerName)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.textPrimary)
                                            Text("\(job.itemSoldDescription) • \(job.isAnticipatedToday() ? "Due Today" : "Scheduled")")
                                                .font(.system(size: 11))
                                                .foregroundColor(.orangeFlame)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        Button {
                                            viewModel.toggleJobCompletion(job: job)
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 12))
                                                Text("Done (+\(formatMoneyNoDecimals(job.pendingCompletionBalance)))")
                                                    .font(.system(size: 11, weight: .bold))
                                            }
                                            .foregroundColor(.darkBg)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.emeraldCompleted)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }

                // Action Tiles Row 1
                HStack(spacing: 10) {
                    BentoActionTile(title: "Pending Pipeline", subtitle: "\(metrics.pendingJobsCount) waiting install", systemImage: "hourglass.top", accentColor: todaySuggestions.isEmpty ? .rosePending : .orangeFlame) {
                        currentScreen = .pendingJobs
                    }
                    BentoActionTile(title: "All Sold Jobs", subtitle: "\(metrics.totalJobsCount) total jobs", systemImage: "list.bullet", accentColor: .cyanAccent) {
                        currentScreen = .jobsList
                    }
                }

                // Action Tiles Row 2
                HStack(spacing: 10) {
                    BentoActionTile(title: "Diagnostics AI", subtitle: "Fault Isolation", systemImage: "brain.head.profile", accentColor: .orangeFlame) {
                        currentScreen = .diagnostic
                    }
                    BentoActionTile(title: "OCR Scanner", subtitle: "Scan Invoices", systemImage: "doc.viewfinder", accentColor: .cyanAccent) {
                        currentScreen = .scanInvoice
                    }
                }

                // Week Summary Card
                BentoCard(backgroundColor: .darkSurfaceElevated, borderColor: summary.isCurrentWeek ? .cyanAccent.opacity(0.6) : .darkSurfaceBorder, borderWidth: 1.5) {
                    HStack {
                        Button { viewModel.previousWeek() } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.textPrimary)
                        }
                        .buttonStyle(.plain)

                        VStack(spacing: 0) {
                            HStack {
                                Text(summary.label)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.textPrimary)
                                if summary.isCurrentWeek {
                                    Text("CURRENT")
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundColor(.emeraldCompleted)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.emeraldCompleted.opacity(0.2))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                }
                            }
                            Text("Week #\(summary.weekOfYear), \(summary.weekYear)")
                                .font(.system(size: 11))
                                .foregroundColor(.textMuted)
                        }
                        .onTapGesture { if !summary.isCurrentWeek { viewModel.resetToCurrentWeek() } }

                        Button { viewModel.nextWeek() } label: {
                            Image(systemName: "chevron.right")
                                .foregroundColor(.textPrimary)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer().frame(height: 14)

                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading) {
                            Text("WEEKLY COMMISSION PAY")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.textSecondary)
                                .tracking(1)
                            Spacer().frame(height: 4)
                            Text(formatMoney(summary.totalWeekCommission))
                                .font(.system(size: 30, weight: .black))
                                .foregroundColor(.goldCommission)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Week Volume")
                                .font(.system(size: 13))
                                .foregroundColor(.textMuted)
                            Text(formatMoney(summary.totalWeekVolume))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.textPrimary)
                        }
                    }

                    Spacer().frame(height: 14)
                    Divider().background(Color.dividerColor)
                    Spacer().frame(height: 12)

                    Text("COMMISSION ENGINE RULE BREAKDOWN")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.cyanAccent)
                        .tracking(0.5)
                    Spacer().frame(height: 8)

                    VStack(spacing: 8) {
                        CommissionRuleRow(ruleTitle: "1(b) Sold This Week (In-Progress)", ruleDesc: "10% payout on active jobs", amount: formatMoney(summary.soldJobsCommission), accentColor: .cyanAccent)
                        CommissionRuleRow(ruleTitle: "1(c) Completed Carryover", ruleDesc: "Remaining 10% on past jobs completed this week", amount: formatMoney(summary.completedCarryoverCommission), accentColor: .emeraldCompleted)
                        CommissionRuleRow(ruleTitle: "1(d) Sold & Completed Same Week", ruleDesc: "Full 20% commission earned in same week", amount: formatMoney(summary.sameWeekSoldAndCompletedCommission), accentColor: .goldCommission)
                        if summary.unitSalesCommission > 0 {
                            CommissionRuleRow(ruleTitle: "2(a) Unit Sales (10% Flat)", ruleDesc: "Direct equipment sales", amount: formatMoney(summary.unitSalesCommission), accentColor: .orangeFlame)
                        }
                    }
                }

                // Lifetime Metrics
                Text("LIFETIME PERFORMANCE & PIPELINE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.textSecondary)
                    .tracking(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 10) {
                    BentoMetricTile(title: "Pending Pipeline", value: formatMoney(metrics.pendingPipelineCommission), subtitle: "\(metrics.pendingJobsCount) jobs waiting install", systemImage: "hourglass.top", valueColor: .rosePending, accentColor: .rosePending, onClick: { currentScreen = .pendingJobs })
                    BentoMetricTile(title: "Gross Margin", value: String(format: "%.1f%%", metrics.grossMarginPercent), subtitle: "\(formatMoney(metrics.totalGrossProfit)) profit", systemImage: "arrow.up.right.trend", valueColor: .emeraldCompleted, accentColor: .emeraldCompleted)
                }

                Spacer().frame(height: 10)

                HStack(spacing: 10) {
                    BentoMetricTile(title: "Total Volume Sold", value: formatMoney(metrics.totalSalesVolume), subtitle: "\(metrics.totalJobsCount) total contracts", systemImage: "dollarsign.circle", valueColor: .textPrimary, accentColor: .cyanAccent)
                    BentoMetricTile(title: "Completed Installs", value: "\(metrics.completedJobsCount) / \(metrics.totalJobsCount)", subtitle: "Installed & Commissioned", systemImage: "checkmark.seal", valueColor: .cyanAccent, accentColor: .cyanAccent)
                }

                // Week Pay Entries
                if !summary.lineItems.isEmpty {
                    HStack {
                        Text("WEEK PAY ENTRIES (\(summary.lineItems.count))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.textSecondary)
                            .tracking(1)
                        Spacer()
                        Text("View Statement")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.cyanAccent)
                            .onTapGesture { currentScreen = .payReport }
                    }

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
                                        .font(.system(size: 11))
                                        .foregroundColor(.textSecondary)
                                        .lineLimit(1)
                                    Spacer().frame(height: 6)
                                    CommissionTypeBadge(typeTag: item.typeTag)
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(formatMoney(item.payoutAmount))
                                        .font(.system(size: 16, weight: .black))
                                        .foregroundColor(.goldCommission)
                                    Text("on \(formatMoney(item.saleAmount)) sale")
                                        .font(.system(size: 11))
                                        .foregroundColor(.textMuted)
                                }
                            }
                            Spacer().frame(height: 6)
                            Text(item.explanation)
                                .font(.system(size: 10))
                                .foregroundColor(.cyanAccent)
                        }
                    }
                }

                // Recent Jobs
                HStack {
                    Text("ALL HVAC JOBS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.textSecondary)
                        .tracking(1)
                    Spacer()
                    Text("See All (\(viewModel.allJobs.count))")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.cyanAccent)
                        .onTapGesture { currentScreen = .jobsList }
                }

                if viewModel.allJobs.isEmpty {
                    BentoCard(backgroundColor: .darkSurface) {
                        VStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .font(.system(size: 36))
                                .foregroundColor(.textMuted)
                            Text("No HVAC jobs logged yet")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.textSecondary)
                            Text("Tap '+' below to record your first sold equipment job.")
                                .font(.system(size: 12))
                                .foregroundColor(.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    ForEach(viewModel.allJobs.prefix(5), id: \.id) { job in
                        BentoCard(backgroundColor: .darkSurface, onClick: {
                            currentScreen = .jobEditor(job)
                        }) {
                            HStack {
                                Button {
                                    viewModel.toggleJobCompletion(job: job)
                                } label: {
                                    Image(systemName: job.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 24))
                                        .foregroundColor(job.isCompleted ? .emeraldCompleted : .textMuted)
                                }
                                .buttonStyle(.plain)

                                Spacer().frame(width: 8)

                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(job.customerName)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.textPrimary)
                                        Spacer()
                                        Text(formatMoney(job.saleAmount))
                                            .font(.system(size: 14, weight: .black))
                                            .foregroundColor(.goldCommission)
                                    }
                                    Text(job.itemSoldDescription)
                                        .font(.system(size: 13))
                                        .foregroundColor(.textSecondary)
                                        .lineLimit(1)

                                    if !job.installationAddress.isEmpty {
                                        Text("📍 \(job.installationAddress)")
                                            .font(.system(size: 10))
                                            .foregroundColor(.cyanAccent)
                                            .lineLimit(1)
                                    }

                                    HStack {
                                        Text(dateStr(for: job))
                                            .font(.system(size: 10))
                                            .foregroundColor(.textMuted)
                                        Spacer()
                                        Text(statusText(for: job))
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(statusColor(for: job))
                                    }
                                    .padding(.top, 2)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .background(Color.darkBg.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.cyanAccent)
                            .frame(width: 32, height: 32)
                        Image(systemName: "snowflake")
                            .foregroundColor(.darkBg)
                            .font(.system(size: 18))
                    }
                    VStack(alignment: .leading) {
                        Text("HVAC COMMISSION PRO")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.textPrimary)
                            .tracking(1)
                        Text("Smart Pay Tracker & Field Diagnostics")
                            .font(.system(size: 10))
                            .foregroundColor(.cyanAccent)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button { currentScreen = .payReport } label: {
                        Image(systemName: "receipt")
                            .foregroundColor(.goldCommission)
                    }
                    Button { currentScreen = .jobsList } label: {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundColor(.textPrimary)
                    }
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button {
                currentScreen = .jobEditor(nil)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.darkBg)
                    .frame(width: 52, height: 52)
                    .background(Color.cyanAccent)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 70)
        }
    }

    private func dateStr(for job: HvacJob) -> String {
        if job.isCompleted, let compTs = job.completedDate {
            return "Sold: \(formatDate(job.soldDate)) • Installed: \(formatDate(compTs))"
        } else {
            return "Sold: \(formatDate(job.soldDate)) • In-Progress"
        }
    }

    private func statusText(for job: HvacJob) -> String {
        if job.jobType == .unitSale { return "10% Unit Sale" }
        if job.isCompleted { return "Completed (20%)" }
        return "In-Progress (10% paid)"
    }

    private func statusColor(for job: HvacJob) -> Color {
        job.isCompleted ? .emeraldCompleted : .cyanAccent
    }
}
