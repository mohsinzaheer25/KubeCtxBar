import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var viewModel: ContextListViewModel
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @State private var backHovered = false
    @State private var githubHovered = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            dividerLine
            contentSection
            Spacer()
            footerSection
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            Button {
                viewModel.showSettings = false
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Back")
                        .font(Design.Font.body)
                }
                .foregroundStyle(backHovered ? Design.Colors.textPrimary : Design.Colors.textSecondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background {
                    Capsule()
                        .fill(backHovered ? Design.Colors.surface2 : Design.Colors.surface1)
                        .overlay {
                            Capsule()
                                .strokeBorder(Design.Colors.border, lineWidth: 0.5)
                        }
                }
            }
            .buttonStyle(.plain)
            .onHover { backHovered = $0 }
            
            Spacer()
            
            Text("Settings")
                .font(Design.Font.title)
                .foregroundStyle(Design.Colors.textPrimary)
            
            Spacer()
            
            // Balance spacer
            Color.clear.frame(width: 70)
        }
        .padding(Design.Layout.padding)
    }
    
    private var dividerLine: some View {
        Rectangle()
            .fill(Design.Colors.border)
            .frame(height: 0.5)
            .padding(.horizontal, Design.Layout.padding)
    }
    
    // MARK: - Content
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: Design.Layout.spacing) {
            // Section header
            Text("GENERAL")
                .font(Design.Font.sectionHeader)
                .foregroundStyle(Design.Colors.textTertiary)
                .padding(.horizontal, 4)
            
            // Launch at Login toggle
            SettingsRow(
                icon: "power",
                iconColor: Design.Colors.green,
                title: "Launch at Login",
                subtitle: "Start KubeCtx when you log in"
            ) {
                Toggle("", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .tint(Design.Colors.green)
            }
            .onChange(of: launchAtLogin) { _, newValue in
                do {
                    if newValue {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    print("Launch at login error: \(error)")
                }
            }
        }
        .padding(Design.Layout.padding)
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Design.Colors.border)
                .frame(height: 0.5)
            
            HStack {
                // App info
                VStack(alignment: .leading, spacing: 2) {
                    Text("KubeCtx")
                        .font(Design.Font.body)
                        .foregroundStyle(Design.Colors.textPrimary)
                    
                    Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                        .font(Design.Font.caption)
                        .foregroundStyle(Design.Colors.textTertiary)
                }
                
                Spacer()
                
                // GitHub link - YELLOW
                Link(destination: URL(string: "https://github.com/mohsinzaheer25/KubeCtxBar")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10, weight: .medium))
                        Text("Star on GitHub")
                            .font(Design.Font.caption)
                    }
                    .foregroundStyle(githubHovered ? .black : .black.opacity(0.8))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background {
                        Capsule()
                            .fill(Design.Colors.yellow)
                            .overlay {
                                Capsule()
                                    .strokeBorder(Design.Colors.yellow.opacity(0.8), lineWidth: 0.5)
                            }
                    }
                }
                .onHover { githubHovered = $0 }
            }
            .padding(Design.Layout.padding)
        }
    }
}

// MARK: - Settings Row

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @ViewBuilder let trailing: () -> Trailing
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor)
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Design.Font.body)
                    .foregroundStyle(Design.Colors.textPrimary)
                
                Text(subtitle)
                    .font(Design.Font.caption)
                    .foregroundStyle(Design.Colors.textTertiary)
            }
            
            Spacer()
            
            trailing()
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: Design.Layout.innerRadius, style: .continuous)
                .fill(isHovered ? Design.Colors.surface2 : Design.Colors.surface1)
                .overlay {
                    RoundedRectangle(cornerRadius: Design.Layout.innerRadius, style: .continuous)
                        .strokeBorder(Design.Colors.border, lineWidth: 0.5)
                }
        }
        .onHover { isHovered = $0 }
        .animation(Design.Animation.fast, value: isHovered)
    }
}
