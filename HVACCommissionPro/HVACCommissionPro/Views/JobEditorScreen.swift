import SwiftUI

struct JobEditorScreen: View {
    @ObservedObject var viewModel: HvacViewModel
    let initialJob: HvacJob?
    @Binding var currentScreen: AppScreen

    private var isEditMode: Bool { initialJob != nil && initialJob!.id != 0 }

    @State private var selectedTab: Int = 0
    @State private var customerName: String = ""
    @State private var customerPhone: String = ""
    @State private var itemSoldDescription: String = ""
    @State private var jobType: JobType = .standardJob
    @State private var saleAmountText: String = ""
    @State private var commissionRateText: String = "20.0"
    @State private var isPcpSold: Bool = false
    @State private var isCompleted: Bool = false
    @State private var soldDateMillis: Double = 0
    @State private var anticipatedDateMillis: Double? = nil
    @State private var completedDateMillis: Double = 0
    @State private var installationAddress: String = ""
    @State private var equipmentDetails: String = ""
    @State private var equipmentCostText: String = ""
    @State private var laborCostText: String = ""
    @State private var materialCostText: String = ""
    @State private var permitCostText: String = ""
    @State private var notes: String = ""
    @State private var systemReadings: String = ""
    @State private var salesProposalSummary: String = ""
    @State private var showDeleteConfirm: Bool = false
    @State private var showSoldDatePicker: Bool = false
    @State private var showAnticipatedDatePicker: Bool = false
    @State private var showCompletedDatePicker: Bool = false

    private var saleAmount: Double { Double(saleAmountText) ?? 0 }
    private var commissionRate: Double { Double(commissionRateText) ?? (jobType == .unitSale ? 10.0 : 20.0) }
    private var pcpSpiff: Double { isPcpSold ? 25.0 : 0.0 }
    private var equipmentCost: Double { Double(equipmentCostText) ?? 0 }
    private var laborCost: Double { Double(laborCostText) ?? 0 }
    private var materialCost: Double { Double(materialCostText) ?? 0 }
    private var permitCost: Double { Double(permitCostText) ?? 0 }
    private var totalCost: Double { equipmentCost + laborCost + materialCost + permitCost }
    private var grossProfit: Double { saleAmount - totalCost }
    private var marginPercent: Double { saleAmount > 0 ? (grossProfit / saleAmount) * 100.0 : 0.0 }
    private var totalCommission: Double { (saleAmount * (commissionRate / 100.0)) + pcpSpiff }
    private var soldAdvance: Double {
        let base = jobType == .unitSale ? (saleAmount * (commissionRate / 100.0)) : (saleAmount * (commissionRate / 100.0) / 2.0)
        return base + pcpSpiff
    }
    private var completionFinal: Double {
        jobType == .unitSale ? 0.0 : (saleAmount * (commissionRate / 100.0) / 2.0)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // Tab Selector
                    HStack(spacing: 4) {
                        tabButton(0, "Basic Tracking", "checkmark.circle")
                        tabButton(1, "Advanced Tracking", "slider.horizontal.3")
                    }
                    .padding(4)
                    .background(Color.darkSurfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    if selectedTab == 0 {
                        basicTrackingView
                    } else {
                        advancedTrackingView
                    }
                }
                .padding(16)
                .padding(.bottom, 80)
            }

            // Bottom Save/Cancel Bar
            HStack(spacing: 12) {
                Button("Cancel") { currentScreen = .dashboard }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.darkSurface)
                    .foregroundColor(.textSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Button {
                    saveJob()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text(isEditMode ? "Save Changes" : "Record Sold Job")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(canSave ? Color.cyanAccent : Color.darkSurface)
                    .foregroundColor(.darkBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canSave)
            }
            .padding(16)
            .background(Color.darkSurfaceElevated)
        }
        .background(Color.darkBg.ignoresSafeArea())
        .navigationTitle(isEditMode ? "Edit HVAC Job" : "Log Sold Equipment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") { currentScreen = .dashboard }
                    .foregroundColor(.textPrimary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    if isEditMode {
                        Button { copyJob() } label: {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.cyanAccent)
                        }
                    }
                    if isEditMode {
                        Button { showDeleteConfirm = true } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.rosePending)
                        }
                    }
                }
            }
        }
        .onAppear { loadInitialJob() }
        .alert("Delete Job Record?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let job = initialJob { viewModel.deleteJob(job) }
                currentScreen = .dashboard
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove this job for \(initialJob?.customerName ?? "")? This action cannot be undone.")
        }
        .sheet(isPresented: $showSoldDatePicker) {
            datePickerSheet(title: "Date Sold", date: Binding(get: { Date(timeIntervalSince1970: soldDateMillis / 1000) }, set: { soldDateMillis = $0.timeIntervalSince1970 * 1000 }), color: .cyanAccent)
        }
        .sheet(isPresented: $showAnticipatedDatePicker) {
            datePickerSheet(title: "Anticipated Completion Date", date: Binding(get: { anticipatedDateMillis != nil ? Date(timeIntervalSince1970: anticipatedDateMillis! / 1000) : Date() }, set: { anticipatedDateMillis = $0.timeIntervalSince1970 * 1000 }), color: .orangeFlame, allowClear: true, onClear: { anticipatedDateMillis = nil })
        }
        .sheet(isPresented: $showCompletedDatePicker) {
            datePickerSheet(title: "Date Completed", date: Binding(get: { completedDateMillis > 0 ? Date(timeIntervalSince1970: completedDateMillis / 1000) : Date() }, set: { completedDateMillis = $0.timeIntervalSince1970 * 1000 }), color: .emeraldCompleted)
        }
    }

    private var canSave: Bool {
        !customerName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !itemSoldDescription.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Tab Button

    private func tabButton(_ index: Int, _ label: String, _ icon: String) -> some View {
        let isSelected = selectedTab == index
        return Button {
            selectedTab = index
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(label)
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundColor(isSelected ? .darkBg : .textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.cyanAccent : Color.darkBg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Basic Tracking View

    private var basicTrackingView: some View {
        VStack(spacing: 16) {
            // Commission Payout Card
            BentoCard(backgroundColor: .darkSurfaceElevated, borderColor: .goldCommission.opacity(0.5), borderWidth: 1.5) {
                Text("ESTIMATED COMMISSION PAYOUT & MARGIN")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.goldCommission)
                    .tracking(1)
                Spacer().frame(height: 10)

                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Commission (\(String(format: "%.0f", commissionRate))%)")
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                        Text(formatMoney(totalCommission))
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(.goldCommission)
                        if isPcpSold {
                            Text("Includes +$25 PCP Spiff")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.emeraldCompleted)
                        }
                    }
                    Spacer()
                    if totalCost > 0 {
                        VStack(alignment: .trailing) {
                            Text("Gross Margin")
                                .font(.system(size: 13))
                                .foregroundColor(.textSecondary)
                            Text(String(format: "%.1f%%", marginPercent))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(marginPercent >= 40 ? .emeraldCompleted : .cyanAccent)
                            Text("Profit: \(formatMoney(grossProfit))")
                                .font(.system(size: 11))
                                .foregroundColor(.textMuted)
                        }
                    }
                }

                Spacer().frame(height: 12)
                Divider().background(Color.dividerColor)
                Spacer().frame(height: 10)

                HStack {
                    VStack(alignment: .leading) {
                        Text(jobType == .unitSale ? "10% Flat Commission" : "10% Advance (Sold)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.cyanAccent)
                        Text(formatMoney(soldAdvance))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.textPrimary)
                    }
                    Spacer()
                    if jobType != .unitSale {
                        VStack(alignment: .trailing) {
                            Text("10% Final (On Install)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(isCompleted ? .emeraldCompleted : .rosePending)
                            Text(formatMoney(completionFinal))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.textPrimary)
                        }
                    }
                }
            }

            // Customer Details
            BentoCard(backgroundColor: .darkSurface) {
                Text("CUSTOMER DETAILS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyanAccent)
                    .tracking(1)
                Spacer().frame(height: 12)
                StyledTextField(title: "Customer Name *", text: $customerName, placeholder: "e.g. John & Lisa Smith", leadingIcon: "person")
            }

            // Scope of Sale
            BentoCard(backgroundColor: .darkSurface) {
                Text("SCOPE OF SALE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyanAccent)
                    .tracking(1)
                Spacer().frame(height: 12)
                StyledTextField(title: "What Was Sold *", text: $itemSoldDescription, placeholder: "e.g. Carrier Infinity 4-Ton Heat Pump + Air Handler", leadingIcon: "snowflake")

                if jobType == .unitSale {
                    Spacer().frame(height: 10)
                    StyledTextField(title: "Equipment Model & Serial Numbers", text: $equipmentDetails, placeholder: "e.g. Model: 25VNA448A003, Serial: 3419E98124")
                }

                Spacer().frame(height: 14)
                Text("Commission Rule Type")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.textSecondary)
                Spacer().frame(height: 6)

                HStack(spacing: 8) {
                    ForEach(JobType.allCases, id: \.self) { type in
                        let isSelected = jobType == type
                        Text(type.shortLabel)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(isSelected ? .darkBg : .textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSelected ? Color.cyanAccent : Color.darkBg)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onTapGesture {
                                jobType = type
                                commissionRateText = String(type.defaultRatePercent)
                            }
                    }
                }
            }

            // Invoice Total & Rate
            BentoCard(backgroundColor: .darkSurface) {
                Text("INVOICE TOTAL & %")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyanAccent)
                    .tracking(1)
                Spacer().frame(height: 12)

                HStack(spacing: 10) {
                    HStack {
                        Text("$")
                            .foregroundColor(.goldCommission)
                            .fontWeight(.black)
                        TextField("Invoice Total ($) *", text: $saleAmountText, prompt: Text("0.00").foregroundColor(.textMuted))
                            .foregroundColor(.textPrimary)
                            .keyboardType(.decimalPad)
                    }
                    .padding(12)
                    .background(Color.darkBg)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.darkSurfaceBorder, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    HStack {
                        TextField("%", text: $commissionRateText)
                            .foregroundColor(.textPrimary)
                            .keyboardType(.decimalPad)
                        Text("%")
                            .foregroundColor(.textSecondary)
                            .fontWeight(.bold)
                    }
                    .padding(12)
                    .background(Color.darkBg)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.darkSurfaceBorder, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Spacer().frame(height: 12)

                // PCP Checkbox
                Toggle(isOn: $isPcpSold) {
                    VStack(alignment: .leading) {
                        Text("Primary Care Plan (PCP) Membership Sold")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isPcpSold ? .goldCommission : .textPrimary)
                        Text("Adds an additional $25 spiff onto total commission")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                    }
                }
                .tint(.cyanAccent)
                .padding(12)
                .background(Color.darkBg)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Job Dates & Installation Schedule
            BentoCard(backgroundColor: .darkSurface) {
                Text("JOB DATES & INSTALLATION SCHEDULE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyanAccent)
                    .tracking(1)
                Spacer().frame(height: 12)

                // Date Sold
                dateRow(label: "Date Sold *", date: soldDateMillis, color: .cyanAccent) { showSoldDatePicker = true }

                Spacer().frame(height: 12)

                // Completion Toggle
                Toggle(isOn: $isCompleted) {
                    VStack(alignment: .leading) {
                        Text(isCompleted ? "Job Completed (Full Commission)" : "Job In-Progress (Pending Install)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isCompleted ? .emeraldCompleted : .cyanAccent)
                        Text(isCompleted ? "Remaining 10% commission unlocked on install date" : "10% sold advance paid now; stored in pipeline until installed")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                    }
                }
                .tint(.emeraldCompleted)
                .padding(12)
                .background(Color.darkBg)
                .clipShape(RoundedRectangle(cornerRadius: 10))

                if !isCompleted {
                    Spacer().frame(height: 12)
                    dateRow(label: "Anticipated / Scheduled Completion Date", date: anticipatedDateMillis, color: .orangeFlame, isOptional: true) { showAnticipatedDatePicker = true }
                }

                if isCompleted {
                    Spacer().frame(height: 12)
                    dateRow(label: "Date Completed / Installed *", date: completedDateMillis, color: .emeraldCompleted) { showCompletedDatePicker = true }
                }
            }

            // Notes
            BentoCard(backgroundColor: .darkSurface) {
                Text("INTERNAL JOB NOTES")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyanAccent)
                    .tracking(1)
                Spacer().frame(height: 12)
                StyledTextField(title: "Internal Job Notes", text: $notes, placeholder: "e.g. Customer wants install scheduled for Tuesday 8 AM.")
            }
        }
    }

    // MARK: - Advanced Tracking View

    private var advancedTrackingView: some View {
        VStack(spacing: 16) {
            // Contact & Location
            BentoCard(backgroundColor: .darkSurface) {
                Text("CONTACT & LOCATION DETAILS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyanAccent)
                    .tracking(1)
                Spacer().frame(height: 12)
                StyledTextField(title: "Customer Phone Number", text: $customerPhone, placeholder: "e.g. (555) 019-2834", keyboardType: .phonePad, leadingIcon: "phone")
                Spacer().frame(height: 10)
                StyledTextField(title: "Installation Address", text: $installationAddress, placeholder: "e.g. 1248 Oak Ridge Dr, Suite 100", leadingIcon: "mappin.and.ellipse")
            }

            // Job Costs
            BentoCard(backgroundColor: .darkSurface) {
                Text("ASSOCIATED JOB COSTS (JOB COSTING)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyanAccent)
                    .tracking(1)
                Spacer().frame(height: 12)

                HStack(spacing: 10) {
                    costField("Equipment Cost", text: $equipmentCostText)
                    costField("Labor Cost", text: $laborCostText)
                }
                Spacer().frame(height: 10)
                HStack(spacing: 10) {
                    costField("Material Cost", text: $materialCostText)
                    costField("Permit & Fees", text: $permitCostText)
                }

                if saleAmount > 0 && totalCost > 0 {
                    Spacer().frame(height: 12)
                    Divider().background(Color.dividerColor)
                    Spacer().frame(height: 10)
                    HStack {
                        Text("Gross Profit: \(formatMoney(grossProfit))")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Text("Margin: \(String(format: "%.1f%%", marginPercent))")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(marginPercent >= 40 ? .emeraldCompleted : .cyanAccent)
                    }
                }
            }

            // Diagnostic Readings
            BentoCard(backgroundColor: .darkSurface) {
                Text("DIAGNOSTIC READINGS & SALES SUMMARY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyanAccent)
                    .tracking(1)
                Spacer().frame(height: 12)
                StyledTextField(title: "Technical System Readings (Superheat, Subcooling, TESP)", text: $systemReadings, placeholder: "e.g. Suction: 118 psig (SH 12°F), Liquid: 335 psig (SC 10°F)")
                Spacer().frame(height: 10)
                StyledTextField(title: "Sales Proposal / Closing Summary", text: $salesProposalSummary, placeholder: "e.g. Recommended dual-fuel heat pump to resolve high winter utility bills.")
            }
        }
    }

    // MARK: - Helper Views

    private func dateRow(label: String, date: Double?, color: Color, isOptional: Bool = false, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(color)
                    .font(.system(size: 18))
                Spacer().frame(width: 10)
                VStack(alignment: .leading) {
                    Text(label)
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                    if let d = date {
                        Text(formatDate(d, format: "EEE, MMM d, yyyy"))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(color)
                    } else if isOptional {
                        Text("Not scheduled (Tap to set date)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.textMuted)
                    } else {
                        Text(formatDate(date ?? Date().timeIntervalSince1970 * 1000, format: "EEE, MMM d, yyyy"))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(color)
                    }
                }
                Spacer()
                Text(isOptional ? "Set Date" : "Change Date")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(color)
            }
            .padding(12)
            .background(Color.darkBg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private func dateRow(label: String, date: Double, color: Color, onTap: @escaping () -> Void) -> some View {
        dateRow(label: label, date: Optional(date), color: color, isOptional: false, onTap: onTap)
    }

    private func costField(_ title: String, text: Binding<String>) -> some View {
        HStack {
            Text("$")
                .foregroundColor(.textMuted)
            TextField(title, text: text, prompt: Text("0.00").foregroundColor(.textMuted))
                .foregroundColor(.textPrimary)
                .keyboardType(.decimalPad)
        }
        .padding(12)
        .background(Color.darkBg)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.darkSurfaceBorder, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func datePickerSheet(title: String, date: Binding<Date>, color: Color, allowClear: Bool = false, onClear: (() -> Void)? = nil) -> some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)

            DatePicker("", selection: date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(color)
                .colorScheme(.dark)

            HStack {
                if allowClear, let onClear = onClear {
                    Button("Clear Date", role: .destructive) { onClear() }
                        .foregroundColor(.rosePending)
                    Spacer()
                } else {
                    Spacer()
                }
                Button("Cancel") { showSoldDatePicker = false; showAnticipatedDatePicker = false; showCompletedDatePicker = false }
                    .foregroundColor(.textSecondary)
                Button("OK") { showSoldDatePicker = false; showAnticipatedDatePicker = false; showCompletedDatePicker = false }
                    .foregroundColor(color)
                    .fontWeight(.bold)
            }
        }
        .padding(16)
        .background(Color.darkSurfaceElevated.ignoresSafeArea())
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func loadInitialJob() {
        guard let job = initialJob else {
            soldDateMillis = Date().timeIntervalSince1970 * 1000
            completedDateMillis = Date().timeIntervalSince1970 * 1000
            return
        }
        customerName = job.customerName
        customerPhone = job.customerPhone
        itemSoldDescription = job.itemSoldDescription
        jobType = job.jobType
        saleAmountText = job.saleAmount > 0 ? String(job.saleAmount) : ""
        commissionRateText = String(job.commissionRate)
        isPcpSold = job.isPcpSold
        isCompleted = job.isCompleted
        soldDateMillis = job.soldDate
        anticipatedDateMillis = job.anticipatedCompletionDate
        completedDateMillis = job.completedDate ?? Date().timeIntervalSince1970 * 1000
        installationAddress = job.installationAddress
        equipmentDetails = job.equipmentDetails
        equipmentCostText = job.equipmentCost > 0 ? String(job.equipmentCost) : ""
        laborCostText = job.laborCost > 0 ? String(job.laborCost) : ""
        materialCostText = job.materialCost > 0 ? String(job.materialCost) : ""
        permitCostText = job.permitCost > 0 ? String(job.permitCost) : ""
        notes = job.notes
        systemReadings = job.systemReadings
        salesProposalSummary = job.salesProposalSummary
    }

    private func saveJob() {
        let saveTime = Date().timeIntervalSince1970 * 1000
        let finalSoldDate = soldDateMillis
        let finalCompletedDate = isCompleted ? completedDateMillis : nil
        let finalAnticipatedDate = !isCompleted ? anticipatedDateMillis : nil

        if let existing = initialJob, existing.id != 0 {
            // Update existing
            existing.customerName = customerName.trimmingCharacters(in: .whitespaces)
            existing.customerPhone = customerPhone.trimmingCharacters(in: .whitespaces)
            existing.soldDate = finalSoldDate
            existing.anticipatedCompletionDate = finalAnticipatedDate
            existing.completedDate = finalCompletedDate
            existing.isCompleted = isCompleted
            existing.itemSoldDescription = itemSoldDescription.trimmingCharacters(in: .whitespaces)
            existing.jobType = jobType
            existing.saleAmount = saleAmount
            existing.commissionRate = commissionRate
            existing.isPcpSold = isPcpSold
            existing.installationAddress = installationAddress.trimmingCharacters(in: .whitespaces)
            existing.equipmentDetails = equipmentDetails.trimmingCharacters(in: .whitespaces)
            existing.equipmentCost = equipmentCost
            existing.laborCost = laborCost
            existing.materialCost = materialCost
            existing.permitCost = permitCost
            existing.notes = notes.trimmingCharacters(in: .whitespaces)
            existing.systemReadings = systemReadings.trimmingCharacters(in: .whitespaces)
            existing.salesProposalSummary = salesProposalSummary.trimmingCharacters(in: .whitespaces)
            existing.updatedAt = saveTime
            viewModel.saveJob(existing) {
                currentScreen = .dashboard
            }
        } else {
            // New job
            let newJob = HvacJob(
                customerName: customerName.trimmingCharacters(in: .whitespaces),
                customerPhone: customerPhone.trimmingCharacters(in: .whitespaces),
                soldDate: finalSoldDate,
                anticipatedCompletionDate: finalAnticipatedDate,
                completedDate: finalCompletedDate,
                isCompleted: isCompleted,
                itemSoldDescription: itemSoldDescription.trimmingCharacters(in: .whitespaces),
                jobType: jobType,
                saleAmount: saleAmount,
                commissionRate: commissionRate,
                isPcpSold: isPcpSold,
                installationAddress: installationAddress.trimmingCharacters(in: .whitespaces),
                equipmentDetails: equipmentDetails.trimmingCharacters(in: .whitespaces),
                equipmentCost: equipmentCost,
                laborCost: laborCost,
                materialCost: materialCost,
                permitCost: permitCost,
                notes: notes.trimmingCharacters(in: .whitespaces),
                systemReadings: systemReadings.trimmingCharacters(in: .whitespaces),
                salesProposalSummary: salesProposalSummary.trimmingCharacters(in: .whitespaces),
                createdAt: saveTime,
                updatedAt: saveTime
            )
            // If pre-filled from diagnostic (has systemReadings but no customerName/itemSoldDescription)
            if let initial = initialJob {
                newJob.systemReadings = initial.systemReadings
                newJob.salesProposalSummary = initial.salesProposalSummary
                if newJob.itemSoldDescription.isEmpty {
                    newJob.itemSoldDescription = initial.itemSoldDescription
                }
            }
            viewModel.saveJob(newJob) {
                currentScreen = .dashboard
            }
        }
    }

    private func copyJob() {
        let saveTime = Date().timeIntervalSince1970 * 1000
        let copy = HvacJob(
            customerName: customerName.endsWith("(Copy)") ? customerName : "\(customerName) (Copy)",
            customerPhone: customerPhone.trimmingCharacters(in: .whitespaces),
            soldDate: saveTime,
            anticipatedCompletionDate: !isCompleted ? anticipatedDateMillis : nil,
            completedDate: nil,
            isCompleted: false,
            itemSoldDescription: itemSoldDescription.trimmingCharacters(in: .whitespaces),
            jobType: jobType,
            saleAmount: saleAmount,
            commissionRate: commissionRate,
            isPcpSold: isPcpSold,
            installationAddress: installationAddress.trimmingCharacters(in: .whitespaces),
            equipmentDetails: equipmentDetails.trimmingCharacters(in: .whitespaces),
            equipmentCost: equipmentCost,
            laborCost: laborCost,
            materialCost: materialCost,
            permitCost: permitCost,
            notes: notes.trimmingCharacters(in: .whitespaces),
            systemReadings: systemReadings.trimmingCharacters(in: .whitespaces),
            salesProposalSummary: salesProposalSummary.trimmingCharacters(in: .whitespaces),
            createdAt: saveTime,
            updatedAt: saveTime
        )
        viewModel.saveJob(copy) {
            currentScreen = .dashboard
        }
    }
}

private extension String {
    func endsWith(_ suffix: String) -> Bool {
        return self.hasSuffix(suffix)
    }
}
