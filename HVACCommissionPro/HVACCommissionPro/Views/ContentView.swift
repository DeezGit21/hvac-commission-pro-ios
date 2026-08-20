import SwiftUI
import SwiftData

enum AppScreen: Hashable {
    case dashboard
    case pendingJobs
    case jobEditor(HvacJob?)
    case jobsList
    case diagnostic
    case scanInvoice
    case payReport
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: HvacViewModel

    init() {
        // Will be re-created with modelContext in onAppear
        _viewModel = StateObject(wrappedValue: HvacViewModel())
    }

    @State private var currentScreen: AppScreen = .dashboard

    var body: some View {
        NavigationStack {
            ZStack {
                Color.darkBg.ignoresSafeArea()

                Group {
                    switch currentScreen {
                    case .dashboard:
                        DashboardScreen(viewModel: viewModel, currentScreen: $currentScreen)
                    case .pendingJobs:
                        PendingJobsScreen(viewModel: viewModel, currentScreen: $currentScreen)
                    case .jobEditor(let job):
                        JobEditorScreen(viewModel: viewModel, initialJob: job, currentScreen: $currentScreen)
                    case .jobsList:
                        JobsListScreen(viewModel: viewModel, currentScreen: $currentScreen)
                    case .diagnostic:
                        DiagnosticScreen(viewModel: viewModel, currentScreen: $currentScreen)
                    case .scanInvoice:
                        ScanInvoiceScreen(viewModel: viewModel, currentScreen: $currentScreen)
                    case .payReport:
                        PayReportScreen(viewModel: viewModel, currentScreen: $currentScreen)
                    }
                }
                .transition(.opacity)
            }
            .overlay(alignment: .bottom) {
                if showBottomBar {
                    BottomTabBar(currentScreen: $currentScreen, viewModel: viewModel)
                }
            }
            .overlay(alignment: .top) {
                if !viewModel.toastMessage.isEmpty {
                    ToastView(message: viewModel.toastMessage)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                viewModel.toastMessage = ""
                            }
                        }
                }
            }
        }
        .onAppear {
            viewModel.modelContextWrapper = modelContext
            viewModel.loadJobs()
        }
    }

    private var showBottomBar: Bool {
        if case .jobEditor = currentScreen { return false }
        if case .scanInvoice = currentScreen { return false }
        return true
    }
}

// MARK: - Bottom Tab Bar

struct BottomTabBar: View {
    @Binding var currentScreen: AppScreen
    @ObservedObject var viewModel: HvacViewModel

    var body: some View {
        HStack(spacing: 0) {
            tabItem(.dashboard, icon: "square.grid.2x2", label: "Home", color: .cyanAccent)
            tabItem(.pendingJobs, icon: "hourglass.top", label: "Pending", color: viewModel.jobsDueToday.isEmpty ? .cyanAccent : .orangeFlame, badge: viewModel.jobsDueToday.isEmpty ? viewModel.pendingJobs.count : viewModel.jobsDueToday.count)
            tabItem(.jobsList, icon: "list.bullet", label: "All Jobs", color: .cyanAccent)
            tabItem(.payReport, icon: "receipt", label: "Payroll", color: .goldCommission)
            tabItem(.diagnostic, icon: "brain.head.profile", label: "AI Tools", color: .orangeFlame)
        }
        .padding(.vertical, 6)
        .background(Color.darkSurfaceElevated)
        .shadow(color: .black.opacity(0.5), radius: 8, y: -4)
    }

    private func tabItem(_ screen: AppScreen, icon: String, label: String, color: Color, badge: Int = 0) -> some View {
        Button {
            currentScreen = screen
        } label: {
            VStack(spacing: 2) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected(screen) ? color : .textMuted)
                    if badge > 0 {
                        Text("\(badge)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.darkBg)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(color)
                            .clipShape(Capsule())
                            .offset(x: 8, y: -6)
                    }
                }
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isSelected(screen) ? color : .textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
    }

    private func isSelected(_ screen: AppScreen) -> Bool {
        switch (currentScreen, screen) {
        case (.dashboard, .dashboard): return true
        case (.pendingJobs, .pendingJobs): return true
        case (.jobsList, .jobsList): return true
        case (.payReport, .payReport): return true
        case (.diagnostic, .diagnostic): return true
        default: return false
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.darkSurfaceElevated)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.3), radius: 8)
            .padding(.top, 8)
    }
}
