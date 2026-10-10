import SwiftUI

/// 3 short steps: welcome → language → permissions (with a plain-language reason for each).
struct OnboardingView: View {
    let onFinish: () -> Void

    @State private var step = 0
    @State private var permissions = PermissionManager()
    @Bindable private var localizer = Localizer.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch step {
                case 0: welcome
                case 1: language
                default: permissionsPage
                }
            }
            .id(step)
            .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index == step ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: index == step ? 22 : 8, height: 8)
                }
            }
            .padding(.bottom, 12)

            Button {
                if step < 2 {
                    withAnimation { step += 1 }
                } else {
                    onFinish()
                }
            } label: {
                Text(step < 2 ? localizer.t("Continue") : localizer.t("Get started"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .animation(.default, value: step)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { permissions.refresh() }
        }
    }

    // MARK: - Steps

    private var welcome: some View {
        VStack(spacing: 18) {
            Image("LogoMark")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
            Text("Metro Mitra")
                .font(.largeTitle.bold())
            Text("Welcome · સ્વાગત છે · स्वागत है")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(localizer.t("Report metro problems in seconds, even without internet."))
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    private var language: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 52))
                .foregroundStyle(.tint)
            Text(localizer.t("Choose your language"))
                .font(.title2.bold())
            VStack(spacing: 10) {
                ForEach(AppLanguage.allCases) { option in
                    Button {
                        localizer.language = option
                    } label: {
                        HStack {
                            Text(option.nativeName).font(.title3)
                            Spacer()
                            if localizer.language == option {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint)
                            }
                        }
                        .padding()
                        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(localizer.language == option ? Color.accentColor : .clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            Text(localizer.t("You can change it any time from the 🌐 menu."))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(24)
    }

    private var permissionsPage: some View {
        VStack(spacing: 16) {
            Text(localizer.t("Two quick permissions"))
                .font(.title2.bold())
            permissionCard(
                icon: "location.fill",
                title: localizer.t("Location"),
                reason: localizer.t("We use it only to find the metro station nearest to you, so you don't have to pick it yourself. It stays on your phone."),
                button: localizer.t("Allow location"),
                state: permissions.location,
                action: permissions.requestLocation
            )
            permissionCard(
                icon: "bell.badge.fill",
                title: localizer.t("Notifications"),
                reason: localizer.t("We alert you when a reported problem is taking too long to fix. Works without internet."),
                button: localizer.t("Allow notifications"),
                state: permissions.notifications,
                action: permissions.requestNotifications
            )
        }
        .padding(24)
    }

    private func permissionCard(
        icon: String, title: String, reason: String, button: String,
        state: PermissionState, action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon).font(.headline)
            Text(reason).font(.subheadline).foregroundStyle(.secondary)
            switch state {
            case .notAsked:
                Button(button, action: action).buttonStyle(.bordered)
            case .granted:
                Label(localizer.t("Allowed"), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.subheadline.weight(.semibold))
            case .denied:
                Label(localizer.t("Not allowed"), systemImage: "xmark.circle.fill")
                    .foregroundStyle(.orange)
                    .font(.subheadline.weight(.semibold))
                Button(localizer.t("Open Settings")) { SystemSettings.open() }
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 14))
    }
}

/// Shows onboarding once, then the app.
struct AppRoot: View {
    let viewModel: IncidentListViewModel
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        Group {
            if hasOnboarded {
                RootTabView(viewModel: viewModel)
                    .transition(.opacity.combined(with: .scale(scale: 1.04)))
            } else {
                OnboardingView { hasOnboarded = true }
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: hasOnboarded)
    }
}
