import Foundation
import UIKit

enum FilterTab: String, CaseIterable {
    case all = "All Jobs"
    case pending = "In-Progress (Pending 10%)"
    case completed = "Completed (Full 20%)"
    case thisWeek = "This Week"
}

enum DiagnosticUiState {
    case idle
    case loading
    case success(DiagnosticResult)
    case error(String)
}

enum ImageScanUiState {
    case idle
    case scanning
    case success(ScannedJobData)
    case error(String)
}

@MainActor
final class HvacViewModel: ObservableObject {

    @Published var allJobs: [HvacJob] = []
    @Published var searchQuery: String = ""
    @Published var filterTab: FilterTab = .all
    @Published var weekOffset: Int = 0
    @Published var diagnosticState: DiagnosticUiState = .idle
    @Published var imageScanState: ImageScanUiState = .idle
    @Published var toastMessage: String = ""

    private var _modelContext: ModelContext?
    var modelContextWrapper: ModelContext? {
        get { _modelContext }
        set { _modelContext = newValue }
    }

    private let geminiService = GeminiHvacService()

    init(modelContext: ModelContext? = nil) {
        self._modelContext = modelContext
        loadJobs()
    }

    // MARK: - Load Jobs

    func loadJobs() {
        guard let context = modelContextWrapper else { return }
        let descriptor = FetchDescriptor<HvacJob>(
            sortBy: [SortDescriptor(\.soldDate, order: .reverse)]
        )
        do {
            allJobs = try context.fetch(descriptor)
        } catch {
            print("Failed to load jobs: \(error)")
        }
    }

    // MARK: - Filtered Jobs

    var filteredJobs: [HvacJob] {
        var filtered = allJobs
        if !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
            filtered = filtered.filter { job in
                job.customerName.lowercased().contains(q) ||
                job.itemSoldDescription.lowercased().contains(q) ||
                job.installationAddress.lowercased().contains(q) ||
                job.equipmentDetails.lowercased().contains(q) ||
                job.notes.lowercased().contains(q)
            }
        }
        switch filterTab {
        case .all:
            return filtered
        case .pending:
            return filtered.filter { !$0.isCompleted }
        case .completed:
            return filtered.filter { $0.isCompleted }
        case .thisWeek:
            let cal = Calendar.current
            let year = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()).yearForWeekOfYear ?? 0
            let week = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()).weekOfYear ?? 1
            let (start, end) = CommissionEngine.getWeekBounds(year: year, weekOfYear: week)
            return filtered.filter { job in
                let soldDate = Date(timeIntervalSince1970: job.soldDate / 1000)
                if soldDate >= start && soldDate <= end { return true }
                if let compTs = job.completedDate {
                    let compDate = Date(timeIntervalSince1970: compTs / 1000)
                    if compDate >= start && compDate <= end { return true }
                }
                return false
            }
        }
    }

    // MARK: - Week Summary

    var selectedWeekPaySummary: WeekPaySummary {
        var cal = Calendar.current
        if weekOffset != 0 {
            cal = cal.date(byAdding: .weekOfYear, value: weekOffset, to: Date) ?? Date()
        }
        let targetWeek = cal.dateComponents([.weekOfYear], from: cal).weekOfYear ?? 1
        let targetYear = cal.dateComponents([.yearForWeekOfYear], from: cal).yearForWeekOfYear ?? 2026
        return CommissionEngine.calculateWeekSummary(year: targetYear, weekOfYear: targetWeek, allJobs: allJobs)
    }

    // MARK: - Lifetime Metrics

    var lifetimeMetrics: LifetimeMetrics {
        CommissionEngine.calculateLifetimeMetrics(allJobs: allJobs)
    }

    // MARK: - Pending Jobs

    var pendingJobs: [HvacJob] {
        allJobs.filter { !$0.isCompleted }
    }

    var jobsDueToday: [HvacJob] {
        allJobs.filter { $0.isAnticipatedToday() || $0.isAnticipatedOverdue() }
    }

    // MARK: - Actions

    func setSearch(_ query: String) {
        searchQuery = query
    }

    func setFilter(_ tab: FilterTab) {
        filterTab = tab
    }

    func nextWeek() {
        weekOffset += 1
    }

    func previousWeek() {
        weekOffset -= 1
    }

    func resetToCurrentWeek() {
        weekOffset = 0
    }

    func updateAnticipatedDate(job: HvacJob, anticipatedMillis: Double?) {
        guard let context = modelContextWrapper else { return }
        job.anticipatedCompletionDate = anticipatedMillis
        job.updatedAt = Date().timeIntervalSince1970 * 1000
        try? context.save()
        loadJobs()
        toastMessage = "Scheduled completion date updated!"
    }

    func saveJob(_ job: HvacJob, onDone: (() -> Void)? = nil) {
        guard let context = modelContextWrapper else { return }
        if job.id == 0 {
            // New job — generate ID
            let newId = (allJobs.map { $0.id }.max() ?? 0) + 1
            job.id = newId
            context.insert(job)
            toastMessage = "Job added successfully!"
        } else {
            job.updatedAt = Date().timeIntervalSince1970 * 1000
            toastMessage = "Job updated successfully!"
        }
        try? context.save()
        loadJobs()
        onDone?()
    }

    func deleteJob(_ job: HvacJob) {
        guard let context = modelContextWrapper else { return }
        context.delete(job)
        try? context.save()
        loadJobs()
        toastMessage = "Job deleted"
    }

    func toggleJobCompletion(job: HvacJob) {
        guard let context = modelContextWrapper else { return }
        job.isCompleted.toggle()
        job.completedDate = job.isCompleted ? Date().timeIntervalSince1970 * 1000 : nil
        job.updatedAt = Date().timeIntervalSince1970 * 1000
        try? context.save()
        loadJobs()
        toastMessage = job.isCompleted ? "Completed (Final 10% unlocked!)" : "Marked In-Progress"
    }

    // MARK: - Diagnostics

    func runDiagnostic(input: DiagnosticInput) {
        Task {
            diagnosticState = .loading
            do {
                let result = try await geminiService.analyzeHvacDiagnostics(input: input)
                diagnosticState = .success(result)
            } catch {
                diagnosticState = .error(error.localizedDescription)
            }
        }
    }

    func clearDiagnosticState() {
        diagnosticState = .idle
    }

    // MARK: - Image Scanning

    func scanImage(image: UIImage) {
        Task {
            imageScanState = .scanning
            do {
                let result = try await geminiService.analyzeImageForJobData(image: image)
                imageScanState = .success(result)
            } catch {
                imageScanState = .error(error.localizedDescription)
            }
        }
    }

    func clearImageScanState() {
        imageScanState = .idle
    }
}
