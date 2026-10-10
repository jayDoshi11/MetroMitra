import SwiftUI

/// Staff incident form.
struct AddIncidentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: AddIncidentViewModel
    let isOnline: Bool

    init(repository: IncidentRepository, isOnline: Bool, onSaved: @escaping () -> Void) {
        self.isOnline = isOnline
        _viewModel = State(initialValue: AddIncidentViewModel(repository: repository, source: .staff, onSaved: onSaved))
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section(tr("Station")) {
                    StationSection(viewModel: viewModel, isOnline: isOnline)
                }

                Section(tr("Details")) {
                    TextField(tr("Describe the problem"), text: $viewModel.note, axis: .vertical)
                        .lineLimit(3...6)
                    Picker(tr("Category"), selection: $viewModel.category) {
                        ForEach(IncidentCategory.allCases) { Text($0.localizedTitle).tag($0) }
                    }
                    Picker(tr("Severity"), selection: $viewModel.severity) {
                        ForEach(Severity.allCases) { Text($0.localizedTitle).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Picker(tr("Route to"), selection: $viewModel.team) {
                        Text(tr("Unassigned")).tag(ResponseTeam?.none)
                        ForEach(ResponseTeam.allCases) { Text($0.localizedName).tag(ResponseTeam?.some($0)) }
                    }
                }

                if let suggestion = viewModel.suggestion {
                    Section(tr("Auto-triage")) {
                        VStack(alignment: .leading, spacing: 6) {
                            Label(
                                trf("Suggested: %@", suggestion.severity.localizedTitle) + (suggestion.category.map { " · " + $0.localizedTitle } ?? ""),
                                systemImage: "sparkles"
                            )
                            .foregroundStyle(.purple)
                            .font(.subheadline.weight(.semibold))

                            Text(trf("Route to %@ · matched: %@", suggestion.team?.localizedName ?? tr("none"), suggestion.reasons.joined(separator: ", ")))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Button(tr("Apply suggestion")) { viewModel.applySuggestion() }
                    }
                }

                Section(tr("Photo")) {
                    PhotoSection(viewModel: viewModel)
                }
            }
            .navigationTitle(tr("New Incident"))
            .navigationBarTitleDisplayMode(.inline)
            .task { viewModel.useMyLocation(isOnline: isOnline) }
            .onChange(of: viewModel.latitude) { _, _ in
                Task { await viewModel.resolveStation() }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(tr("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(tr("Save")) {
                        viewModel.save()
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
}
