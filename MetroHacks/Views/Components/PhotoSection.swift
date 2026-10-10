import SwiftUI
import PhotosUI

struct PhotoSection: View {
    @Bindable var viewModel: AddIncidentViewModel

    var body: some View {
        if let image = viewModel.photoImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Button(tr("Remove photo"), role: .destructive) {
                viewModel.removePhoto()
            }
        }
        PhotosPicker(selection: $viewModel.photoItem, matching: .images) {
            Label(viewModel.photoImage == nil ? tr("Attach photo") : tr("Change photo"),
                  systemImage: "photo.on.rectangle")
        }
    }
}
