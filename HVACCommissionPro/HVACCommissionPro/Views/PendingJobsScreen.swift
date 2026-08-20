import SwiftUI

struct PendingJobsScreen: View {
    @ObservedObject var viewModel: HvacViewModel
    @Binding var currentScreen: AppScreen

    @State private var searchQuery: String = ""
    @State private var selectedFilter: Int = 0
    @State private var jobForDatePicker: HvacJob? = nil
    @State private var showDatePicker: Bool = false

    private var pendingJobs: [HvacJob] { viewModel.pendingJobs }

    private var totalPendingCommission: Double {
        pendingJobs.reduce(0) { $0 + $1.pendingCompletionBalance }
    }
    private var totalPendingVolume: Double {
        pendingJobs.reduce(0) { $0 + $1.saleAmount }
    }
    private var todayJobs: [HvacJob] {
        pendingJobs.filter { $0.isAnticipatedToday() || $0.isAnticipatedOverdue() }
    }

    private var filteredJobs: [HvacJob] {
        var list = searchQuery.isEmpty ? pendingJobs : {
            let q = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
            return pendingJobs.filter {
                $0.customerName.lowercased().contains(q) ||
                $0.itemSoldDescription.lowercased().contains(q) ||
                $0.installationAddress.lowercased().contains(q) ||
                $0.customerPhone.contains(q)
            }
        }()
        switch selectedFilter {
        case 1: list = list.filter { $0.isAnticipatedToday() || $0.isAnticipatedOverdue() }
        case 2: list = list.filter { $0.anticipatedCompletionDate != nil && !$0.isAnticipatedToday() && !$0.isAnticipatedOverdue() }
        case 3: list = list.filter { $0.anticipatedCompletionDate == nil }
        default: break
        }
        return list
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Pipeline Summary Header
                BentoCard(backgroundColor: .darkSurfaceElevated, borderColor: .cyanAccent.opacity(0.3), borderWidth: 1.5) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("UNCLAIMED INSTALL COMMISSIONS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.cyanAccent)
                                .tracking(1)
                            Text(formatMoneyNoDecimals(totalPendingCommission))
                                .font(.system(size: 22, weight: .black))
                                .foregroundColor(.goldCommission)
                        }
                        Spacer()
                        Text("\(pendingJobs.count) Jobs Pending")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.cyanAccent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.cyanAccent.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Spacer().frame(height: 10)
                    Divider().background(Color.dividerColor)
                    Spacer().frame(height: 10)

                    HStack {
                        Text("Pending Equipment Sales Volume:")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text(formatMoneyNoDecimals(totalPendingVolume))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textPrimary)
                    }
                }

                // Today's Suggestions
                if !todayJobs.isEmpty && selectedFilter != 2 && selectedFilter != 3 {
                    BentoCard(backgroundColor: Color(red: 0.125, green: 0.090, blue: 0.039), borderColor: .orangeFlame, borderWidth: 1.5) {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.orangeFlame)
                                .font(.system(size: 18))
                            Text("READY FOR COMPLETION TODAY (\(todayJobs.count))")
                                .font(.system(size: 12, weight: .black))
                                .foregroundColor(.orangeFlame)
                                .tracking(0.5)
                        }
                        Text("These sold jobs have anticipated install dates for today. Mark them done to unlock your remaining commission payout!")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                            .padding(.top, 4)
                            .padding(.bottom, 10)

                        ForEach(todayJobs, id: \.id) { job in
                            PendingJobCard(
                                job: job,
                                onComplete: { viewModel.toggleJobCompletion(job: job) },
                                onEditDate: {
                                    jobForDatePicker = job
                                    showDatePicker = true
                                },
                                onClick: { currentScreen = .jobEditor(job) }
                            )
                        }
                    }
                }

                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.cyanAccent)
                    TextField("", text: $searchQuery, prompt: Text("Search pending jobs by customer or equipment...").foregroundColor(.textMuted))
                        .foregroundColor(.textPrimary)
                    if !searchQuery.isEmpty {
                        Button { searchQuery = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.textMuted)
                        }
                    }
                }
                .padding(12)
                .background(Color.darkSurface)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.darkSurfaceBorder, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip("All (\(pendingJobs.count))", isSelected: selectedFilter == 0, color: .cyanAccent) { selectedFilter = 0 }
                        if !todayJobs.isEmpty {
                            filterChip("Today (\(todayJobs.count))", isSelected: selectedFilter == 1, color: .orangeFlame) { selectedFilter = 1 }
                        }
                        filterChip("Scheduled", isSelected: selectedFilter == 2, color: .cyanAccent) { selectedFilter = 2 }
                        filterChip("Unscheduled", isSelected: selectedFilter == 3, color: .cyanAccent) { selectedFilter = 3 }
                    }
                }

                // Job List
                if filteredJobs.isEmpty {
                    BentoCard(backgroundColor: .darkSurface) {
                        VStack(spacing: 10) {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.emeraldCompleted)
                            Text(pendingJobs.isEmpty ? "Pipeline Clear!" : "No matching pending jobs")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.textPrimary)
                            Text(pendingJobs.isEmpty ? "All sold jobs have been successfully installed and completed." : "Try adjusting your search query or filter.")
                                .font(.system(size: 12))
                                .foregroundColor(.textMuted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                    }
                } else {
                    ForEach(filteredJobs, id: \.id) { job in
                        PendingJobCard(
                            job: job,
                            onComplete: { viewModel.toggleJobCompletion(job: job) },
                            onEditDate: {
                                jobForDatePicker = job
                                showDatePicker = true
                            },
                            onClick: { currentScreen = .jobEditor(job) }
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
        }
        .background(Color.darkBg.ignoresSafeArea())
        .navigationTitle("Pending Pipeline")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") { currentScreen = .dashboard }
                    .foregroundColor(.textPrimary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { currentScreen = .jobEditor(nil) } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.cyanAccent)
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            if let job = jobForDatePicker {
                DatePickerSheet(
                    initialDate: job.anticipatedCompletionDate != nil ? Date(timeIntervalSince1970: job.anticipatedCompletionDate! / 1000) : Date(),
                    onSave: { newDate in
                        viewModel.updateAnticipatedDate(job: job, anticipatedMillis: newDate.timeIntervalSince1970 * 1000)
                        showDatePicker = false
                    },
                    onClear: {
                        viewModel.updateAnticipatedDate(job: job, anticipatedMillis: nil)
                        showDatePicker = false
                    },
                    onCancel: { showDatePicker = false }
                )
                .presentationDetents([.medium])
            }
        }
    }

    private func filterChip(_ label: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                .foregroundColor(isSelected ? .darkBg : .textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color.darkSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pending Job Card

struct PendingJobCard: View {
    let job: HvacJob
    let onComplete: () -> Void
    let onEditDate: () -> Void
    let onClick: () -> Void

    private var isDueToday: Bool { job.isAnticipatedToday() }
    private var isOverdue: Bool { job.isAnticipatedOverdue() }

    private var cardBorder: Color {
        if isDueToday { return .orangeFlame }
        if isOverdue { return .rosePending }
        if job.anticipatedCompletionDate != nil { return .cyanAccent.opacity(0.4) }
        return .darkSurfaceBorder
    }

    var body: some View {
        BentoCard(backgroundColor: .darkSurface, borderColor: cardBorder, borderWidth: 1, onClick: onClick) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(job.customerName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.textPrimary)
                            if job.isPcpSold {
                                Text("PCP +$25")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.purplePcp)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.purplePcp.opacity(0.2))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        Text(job.itemSoldDescription)
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                        if !job.installationAddress.isEmpty {
                            Text(job.installationAddress)
                                .font(.system(size: 11))
                                .foregroundColor(.textMuted)
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(formatMoney(job.saleAmount))
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.textPrimary)
                        Text("Remaining: +\(formatMoneyNoDecimals(job.pendingCompletionBalance))")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.goldCommission)
                    }
                }

                Spacer().frame(height: 10)
                Divider().background(Color.dividerColor)
                Spacer().frame(height: 10)

                HStack {
                    VStack(alignment: .leading) {
                        Text("Sold: \(formatDate(job.soldDate))")
                            .font(.system(size: 10))
                            .foregroundColor(.textMuted)
                        if let anticipated = job.anticipatedCompletionDate {
                            let dateStr = formatDate(anticipated)
                            let label = isDueToday ? "⚡ Due Today (\(dateStr))" : (isOverdue ? "⚠️ Overdue (\(dateStr))" : "📅 Scheduled: \(dateStr)")
                            let color = isDueToday ? Color.orangeFlame : (isOverdue ? Color.rosePending : Color.cyanAccent)
                            Text(label)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(color)
                                .onTapGesture { onEditDate() }
                        } else {
                            Text("🗓️ No install date set (Tap to schedule)")
                                .font(.system(size: 11))
                                .foregroundColor(.textMuted)
                                .onTapGesture { onEditDate() }
                        }
                    }
                    Spacer()
                    HStack(spacing: 8) {
                        Button { onEditDate() } label: {
                            Image(systemName: "calendar.badge.plus")
                                .foregroundColor(job.anticipatedCompletionDate != nil ? .cyanAccent : .textMuted)
                                .font(.system(size: 18))
                        }
                        .buttonStyle(.plain)

                        Button { onComplete() } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14))
                                Text("Done")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(.darkBg)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
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

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    let initialDate: Date
    let onSave: (Date) -> Void
    let onClear: () -> Void
    let onCancel: () -> Void

    @State private var selectedDate: Date

    init(initialDate: Date, onSave: @escaping (Date) -> Void, onClear: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.initialDate = initialDate
        self.onSave = onSave
        self.onClear = onClear
        self.onCancel = onCancel
        _selectedDate = State(initialValue: initialDate)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Schedule Completion Date")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.orangeFlame)

            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(.orangeFlame)
                .colorScheme(.dark)

            HStack {
                Button("Clear Date", role: .destructive) { onClear() }
                    .foregroundColor(.rosePending)
                Spacer()
                Button("Cancel") { onCancel() }
                    .foregroundColor(.textSecondary)
                Button("Save Date") { onSave(selectedDate) }
                    .foregroundColor(.orangeFlame)
                    .fontWeight(.bold)
            }
        }
        .padding(16)
        .background(Color.darkSurfaceElevated.ignoresSafeArea())
    }
}
