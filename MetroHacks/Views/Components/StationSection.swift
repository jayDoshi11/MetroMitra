import SwiftUI

/// Station picker that auto-fills from GPS. Used by both the staff form and the passenger form.
struct StationSection: View {
    @Bindable var viewModel: AddIncidentViewModel
    let isOnline: Bool

    var body: some View {
        Picker(tr("Station"), selection: $viewModel.station) {
            Text(tr("Select station")).tag("")
            if !viewModel.station.isEmpty && !StationDirectory.contains(viewModel.station) {
                Text(tr(viewModel.station)).tag(viewModel.station)
            }
            ForEach(StationDirectory.all) { station in
                Text(tr(station.name)).tag(station.name)
            }
        }

        if viewModel.isLocating || (viewModel.isResolvingStation && viewModel.detectedStation == nil) {
            HStack(spacing: 8) {
                ProgressView()
                Text(tr("Finding nearest station…")).foregroundStyle(.secondary)
            }
        } else if let detected = viewModel.detectedStation {
            Label(
                trf("Nearest: %@ · %@", tr(detected.name), detected.distanceText),
                systemImage: "location.fill"
            )
            .font(.footnote)
            .foregroundStyle(.green)
        } else if let far = viewModel.farStation {
            VStack(alignment: .leading, spacing: 6) {
                Text(tr("No metro station within 2 km of you."))
                    .font(.footnote).foregroundStyle(.secondary)
                Button(trf("Nearest is %@ (%@) – use it", tr(far.name), far.distanceText)) {
                    viewModel.selectFarStation()
                }
                .font(.footnote)
            }
        } else if let message = viewModel.locationMessage {
            Text(message).font(.footnote).foregroundStyle(.secondary)
        }

        Button {
            if viewModel.locationDenied {
                SystemSettings.open()   // permission was refused: send them to Settings to allow it
            } else {
                viewModel.useMyLocation(isOnline: isOnline)
            }
        } label: {
            Label(tr("Use my location"), systemImage: "location")
        }
    }
}
