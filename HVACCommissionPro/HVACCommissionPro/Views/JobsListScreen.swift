import SwiftUI

struct JobsListScreen: View {
    @ObservedObject var viewModel: HvacViewModel
    @Binding var currentScreen: AppScreen

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.textMuted)
                TextField("", text: $viewModel.searchQuery, prompt: Text("Search customer, equipment, address...").foregroundColor(.textMuted))
                    .foregroundColor(.textPrimary)
                if !viewModel.searchQuery.isEmpty {
                    Button { viewModel.setSearch("") } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textMuted)
                    }
                }
            }
            .padding(12)
            .background(Color.darkSurface)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.darkSurfaceBorder, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Filter Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(FilterTab.allCases, id: \.self) { tab in
                        let isSelected = viewModel.filterTab == tab
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: isSelected ? .bold : .regular))
                            .foregroundColor(isSelected ? .darkBg : .textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.cyanAccent : Color.darkSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onTapGesture { viewModel.setFilter(tab) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
            }

            Text("\(viewModel.filteredJobs.count) JOBS FOUND")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.textMuted)
                .tracking(0.5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            if viewModel.filteredJobs.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.textMuted)
                    Text("No matching jobs found")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textSecondary)
                    Text("Try adjusting your search or filter criteria.")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.filteredJobs, id: \.id) { job in
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
                                                .font(.system(size: 11))
                                                .foregroundColor(.cyanAccent)
                                                .lineLimit(1)
                                        }

                                        Spacer().frame(height: 6)

                                        HStack {
                                            HStack(spacing: 6) {
                                                JobTypeBadge(jobType: job.jobType)
                                                StatusBadge(isCompleted: job.isCompleted)
                                            }
                                            Spacer()
                                            dateText(for: job)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
        }
        .background(Color.darkBg.ignoresSafeArea())
        .navigationTitle("HVAC Jobs Database")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Back") { currentScreen = .dashboard }
                    .foregroundColor(.textPrimary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    currentScreen = .jobEditor(nil)
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.cyanAccent)
                }
            }
        }
    }

    @ViewBuilder
    private func dateText(for job: HvacJob) -> some View {
        if job.isCompleted, let compTs = job.completedDate {
            Text("Installed: \(formatDate(compTs))")
                .font(.system(size: 10))
                .foregroundColor(.emeraldCompleted)
        } else if job.isAnticipatedToday() {
            Text("⚡ Due Today")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.orangeFlame)
        } else if let anticipated = job.anticipatedCompletionDate {
            Text("📅 Sched: \(formatDate(anticipated))")
                .font(.system(size: 10))
                .foregroundColor(.textMuted)
        } else {
            Text("Sold: \(formatDate(job.soldDate)) • Pending")
                .font(.system(size: 10))
                .foregroundColor(.textMuted)
        }
    }
}
