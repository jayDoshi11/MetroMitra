import SwiftUI

struct StatusBannerView: View {
    let isOnline: Bool
    let pendingCount: Int
    let isSyncing: Bool
    var overdueCount: Int = 0

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isOnline ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            Text(isOnline ? tr("Online") : tr("Offline"))
                .font(.subheadline.weight(.semibold))

            if overdueCount > 0 {
                Label(trf("%d overdue", overdueCount), systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
            }

            Spacer()
            if isSyncing {
                ProgressView().controlSize(.small)
                Text(tr("Syncing…")).foregroundStyle(.secondary)
            } else {
                Text(trf("%d pending sync", pendingCount)).contentTransition(.numericText()).foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
        .animation(.snappy, value: isOnline)
        .animation(.snappy, value: pendingCount)
        .animation(.snappy, value: overdueCount)
        .animation(.snappy, value: isSyncing)
    }
}

#Preview {
    StatusBannerView(isOnline: false, pendingCount: 3, isSyncing: false, overdueCount: 2)
        .padding()
}
