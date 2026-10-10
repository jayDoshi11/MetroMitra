import SwiftUI

struct IncidentListView: View {
	@Bindable var viewModel: IncidentListViewModel
	@State private var showAdd = false
	@State private var showDashboard = false
	@State private var confirmDeleteAll = false
	
	var body: some View {
		NavigationStack {
			TimelineView(.periodic(from: .now, by: 10)) { context in
				content(now: context.date)
			}
			.navigationTitle(tr("Metro Control"))
			.toolbar {
				ToolbarItem(placement: .topBarLeading) {
					Button { showDashboard = true } label: { Image(systemName: "chart.bar.xaxis") }
				}
				ToolbarItem(placement: .topBarLeading) { LanguageMenu() }
				ToolbarItem(placement: .topBarTrailing) {
					Menu {
						Button(tr("Load sample data"), systemImage: "tray.and.arrow.down") {
							withAnimation { viewModel.loadSampleData() }
						}
						Toggle(tr("Demo SLA (1 / 2 / 5 min)"), isOn: $viewModel.demoMode)
						Button(tr("Delete all"), systemImage: "trash", role: .destructive) {
							confirmDeleteAll = true
						}
					} label: {
						Image(systemName: "ellipsis.circle")
					}
				}
				ToolbarItem(placement: .topBarTrailing) {
					Button { showAdd = true } label: { Image(systemName: "plus") }
				}
			}
			.sheet(isPresented: $showAdd) {
				AddIncidentView(repository: viewModel.repository, isOnline: viewModel.isOnline) {
					viewModel.load()
					Task { await viewModel.syncPending() }
				}
			}
			.sheet(isPresented: $showDashboard) {
				DashboardView(
					viewModel: DashboardViewModel(
						incidents: viewModel.incidents,
						policy: viewModel.policy,
						now: .now
					)
				)
			}
			.confirmationDialog(tr("Delete all incidents?"), isPresented: $confirmDeleteAll, titleVisibility: .visible) {
				Button(tr("Delete all"), role: .destructive) { 
					withAnimation { viewModel.deleteAll() } 
				}
			}
			.task {
				viewModel.load()
				await viewModel.syncPending()
			}
			.onChange(of: viewModel.isOnline) { _, online in
				if online { Task { await viewModel.syncPending() } }
			}
		}
	}
	
	private func content(now: Date) -> some View {
		let visible = viewModel.visibleIncidents(now: now)
		
		return List {
			Section {
				StatusBannerView(
					isOnline: viewModel.isOnline,
					pendingCount: viewModel.pendingCount,
					isSyncing: viewModel.isSyncing,
					overdueCount: viewModel.overdueCount(now: now)
				)
			}
			.listRowSeparator(.hidden)
			
			Section {
				// FLaw fixed: Drive the picker with a snappy animation to make segment switching fluid
				Picker(tr("Filter"), selection: $viewModel.filter.animation(.snappy)) {
					ForEach(IncidentFilter.allCases) { Text($0.localizedTitle).tag($0) }
				}
				.pickerStyle(.segmented)
			}
			.listRowSeparator(.hidden)
			
			Section(tr("Incidents")) {
				if visible.isEmpty {
					ContentUnavailableView(
						tr("Nothing here"),
						systemImage: "tram.fill",
						description: Text(tr("Tap + to log an incident, or load sample data from the menu."))
					)
					.transition(.scale(scale: 0.95).combined(with: .opacity))
				} else {
					ForEach(visible) { incident in
						NavigationLink {
							IncidentDetailView(incident: incident, viewModel: viewModel)
						} label: {
							IncidentRowView(incident: incident, now: now, policy: viewModel.policy)
						}
						.swipeActions(edge: .trailing) {
							if incident.status == .resolved {
								// FLaw fixed: Wrap data mutations in withAnimation
								Button(tr("Reopen")) { withAnimation(.spring) { viewModel.reopen(incident) } }.tint(.blue)
							} else {
								Button(tr("Resolve")) { withAnimation(.spring) { viewModel.resolve(incident) } }.tint(.green)
							}
						}
					}
					.onDelete { offsets in
						withAnimation(.spring) { viewModel.delete(offsets.map { visible[$0] }) }
					}
				}
			}
		}
		// Allows the list layout to smoothly adapt when items are inserted/removed
		.animation(.spring(response: 0.4, dampingFraction: 0.8), value: visible.count)
	}
}








































//import SwiftUI
//
//struct IncidentListView: View {
//    @Bindable var viewModel: IncidentListViewModel
//    @State private var showAdd = false
//    @State private var showDashboard = false
//    @State private var confirmDeleteAll = false
//
//    var body: some View {
//        NavigationStack {
//            TimelineView(.periodic(from: .now, by: 10)) { context in
//                content(now: context.date)
//            }
//            .navigationTitle(tr("Metro Control"))
//            .toolbar {
//                ToolbarItem(placement: .topBarLeading) {
//                    Button { showDashboard = true } label: { Image(systemName: "chart.bar.xaxis") }
//                }
//                ToolbarItem(placement: .topBarLeading) { LanguageMenu() }
//                ToolbarItem(placement: .topBarTrailing) {
//                    Menu {
//                        Button(tr("Load sample data"), systemImage: "tray.and.arrow.down") {
//                            viewModel.loadSampleData()
//                        }
//                        Toggle(tr("Demo SLA (1 / 2 / 5 min)"), isOn: $viewModel.demoMode)
//                        Button(tr("Delete all"), systemImage: "trash", role: .destructive) {
//                            confirmDeleteAll = true
//                        }
//                    } label: {
//                        Image(systemName: "ellipsis.circle")
//                    }
//                }
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button { showAdd = true } label: { Image(systemName: "plus") }
//                }
//            }
//            .sheet(isPresented: $showAdd) {
//                AddIncidentView(repository: viewModel.repository, isOnline: viewModel.isOnline) {
//                    viewModel.load()
//                    Task { await viewModel.syncPending() }
//                }
//            }
//            .sheet(isPresented: $showDashboard) {
//                DashboardView(
//                    viewModel: DashboardViewModel(
//                        incidents: viewModel.incidents,
//                        policy: viewModel.policy,
//                        now: .now
//                    )
//                )
//            }
//            .confirmationDialog(tr("Delete all incidents?"), isPresented: $confirmDeleteAll, titleVisibility: .visible) {
//                Button(tr("Delete all"), role: .destructive) { viewModel.deleteAll() }
//            }
//            .task {
//                viewModel.load()
//                await viewModel.syncPending()
//            }
//            .onChange(of: viewModel.isOnline) { _, online in
//                if online { Task { await viewModel.syncPending() } }
//            }
//        }
//    }
//
//    private func content(now: Date) -> some View {
//        let visible = viewModel.visibleIncidents(now: now)
//
//        return List {
//            Section {
//                StatusBannerView(
//                    isOnline: viewModel.isOnline,
//                    pendingCount: viewModel.pendingCount,
//                    isSyncing: viewModel.isSyncing,
//                    overdueCount: viewModel.overdueCount(now: now)
//                )
//            }
//
//            Section {
//                Picker(tr("Filter"), selection: $viewModel.filter) {
//                    ForEach(IncidentFilter.allCases) { Text($0.localizedTitle).tag($0) }
//                }
//                .pickerStyle(.segmented)
//            }
//
//            Section(tr("Incidents")) {
//                if visible.isEmpty {
//                    ContentUnavailableView(
//                        tr("Nothing here"),
//                        systemImage: "tram.fill",
//                        description: Text(tr("Tap + to log an incident, or load sample data from the menu."))
//                    )
//                } else {
//                    ForEach(visible) { incident in
//                        NavigationLink {
//                            IncidentDetailView(incident: incident, viewModel: viewModel)
//                        } label: {
//                            IncidentRowView(incident: incident, now: now, policy: viewModel.policy)
//                        }
//                        .swipeActions(edge: .trailing) {
//                            if incident.status == .resolved {
//                                Button(tr("Reopen")) { viewModel.reopen(incident) }.tint(.blue)
//                            } else {
//                                Button(tr("Resolve")) { viewModel.resolve(incident) }.tint(.green)
//                            }
//                        }
//                    }
//                    .onDelete { offsets in
//                        viewModel.delete(offsets.map { visible[$0] })
//                    }
//                }
//            }
//        }
//    }
//}
