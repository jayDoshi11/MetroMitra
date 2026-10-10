import SwiftUI

/// Passenger tab: report a problem in a few taps. Triage and routing happen automatically.
struct PassengerReportView: View {
    let viewModel: IncidentListViewModel

    var body: some View {
        NavigationStack {
            PassengerReportForm(listViewModel: viewModel)
        }
    }
}

struct PassengerReportForm: View {
    let listViewModel: IncidentListViewModel
    private let lockedStation: Bool
    @State private var bounce = false
    @State private var form: AddIncidentViewModel

    init(listViewModel: IncidentListViewModel, initialStation: String? = nil) {
        self.listViewModel = listViewModel
        self.lockedStation = initialStation != nil
        _form = State(initialValue: AddIncidentViewModel(
            repository: listViewModel.repository,
            source: .passenger,
            initialStation: initialStation,
            onSaved: {
                listViewModel.load()
                Task { await listViewModel.syncPending() }
            }
        ))
    }

    var body: some View {
        Group {
            if let summary = form.submitted {
                successView(summary)
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
            } else {
                formView
                    .transition(.opacity)
            }
        }
        .animation(.spring(duration: 0.45), value: form.submitted != nil)
        .sensoryFeedback(.success, trigger: form.submitted != nil)
        .navigationTitle(tr("Report a problem"))
        .toolbar { ToolbarItem(placement: .topBarTrailing) { LanguageMenu() } }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var formView: some View {
        @Bindable var form = form

        return Form {
            Section(tr("Where are you?")) {
                StationSection(viewModel: form, isOnline: listViewModel.isOnline)
            }

            Section(tr("What's wrong?")) {
                ForEach(IncidentCategory.allCases) { category in
                    Button {
                        form.category = category
                    } label: {
                        HStack {
                            Image(systemName: category.systemImage).frame(width: 28)
                            Text(category.localizedTitle)
                            Spacer()
                            if form.categoryTouched && form.category == category {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
                TextField(tr("Tell us what you see (optional)"), text: $form.note, axis: .vertical)
                    .lineLimit(2...5)
            }

            if let suggestion = form.suggestion {
                Section {
                    Label(
                        trf("We'll treat this as %@ priority", suggestion.severity.localizedTitle),
                        systemImage: "sparkles"
                    )
                    .foregroundStyle(.purple)
                    .font(.footnote)
                }
            }

            Section(tr("Photo (optional)")) {
                PhotoSection(viewModel: form)
            }

            Section {
                Button {
                    form.save()
                } label: {
                    Text(tr("Send report")).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!form.canSubmit)
            } footer: {
                Text(tr("Works offline. If you have no signal, your report is saved and sent automatically."))
            }
        }
        .task {
            // Opened from a station page: the station is already known, so don't auto-detect.
            if !lockedStation { form.useMyLocation(isOnline: listViewModel.isOnline) }
        }
        .onChange(of: form.latitude) { _, _ in
            if !lockedStation { Task { await form.resolveStation() } }
        }
    }

    private func successView(_ summary: AddIncidentViewModel.Submission) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, value: bounce)
                .onAppear { bounce.toggle() }
            Text(tr("Report sent")).font(.title2.bold())
            VStack(spacing: 6) {
                Text(trf("%1$@ at %2$@", summary.category.localizedTitle, tr(summary.station)))
                Text(trf("Priority: %@", summary.severity.localizedTitle) + (summary.team.map { " · " + trf("Routed to %@", $0.rawValue) } ?? ""))
                    .foregroundStyle(.secondary)
                if let merged = summary.mergedCount {
                    Label(trf("Added to an existing issue. %d passengers have reported it.", merged), systemImage: "person.3.fill")
                        .font(.footnote)
                        .foregroundStyle(.blue)
                        .multilineTextAlignment(.center)
                }
                if summary.queuedOffline {
                    Text(tr("Saved on your phone. It will send automatically when you're back online."))
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                }
            }
            Button(tr("Report another")) {
                form = AddIncidentViewModel(
                    repository: listViewModel.repository,
                    source: .passenger,
                    onSaved: {
                        listViewModel.load()
                        Task { await listViewModel.syncPending() }
                    }
                )
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
