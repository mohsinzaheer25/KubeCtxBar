import SwiftUI

struct ContextRowView: View {
    let context: KubeContext
    let isActive: Bool
    let isSelected: Bool
    let isFlashing: Bool
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Status indicator (green dot for active)
                statusIndicator
                
                // Context info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(context.displayName)
                            .font(Design.Font.body)
                            .foregroundStyle(isActive ? Design.Colors.textPrimary : Design.Colors.textSecondary)
                            .lineLimit(1)
                        
                        // Provider badge
                        if let badge = context.providerBadge {
                            ProviderBadge(text: badge, provider: context.cloudProvider)
                        }
                    }
                    
                    // Cluster name if different
                    if shouldShowCluster {
                        Text(context.displayClusterName)
                            .font(Design.Font.caption)
                            .foregroundStyle(Design.Colors.textTertiary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Namespace badge
                if let ns = context.namespace, !ns.isEmpty {
                    NamespaceBadge(namespace: ns)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .cardBackground(isHovered: isHovered || isSelected, isActive: isActive)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(Design.Animation.fast, value: isHovered)
        .animation(Design.Animation.smooth, value: isActive)
        .overlay {
            if isFlashing {
                RoundedRectangle(cornerRadius: Design.Layout.rowRadius, style: .continuous)
                    .fill(Design.Colors.green.opacity(0.15))
                    .animation(Design.Animation.bounce, value: isFlashing)
            }
        }
    }
    
    private var statusIndicator: some View {
        ZStack {
            // Green fill for active
            Circle()
                .fill(isActive ? Design.Colors.green : .clear)
                .frame(width: 10, height: 10)
            
            // Border
            Circle()
                .strokeBorder(
                    isActive ? Design.Colors.green : Design.Colors.textTertiary,
                    lineWidth: isActive ? 0 : 1.5
                )
                .frame(width: 10, height: 10)
        }
        .frame(width: 16, height: 16)
    }
    
    private var shouldShowCluster: Bool {
        let display = context.displayName
        let cluster = context.displayClusterName
        return !cluster.isEmpty && cluster != display && !display.contains(cluster)
    }
}

// MARK: - Provider Badge

struct ProviderBadge: View {
    let text: String
    let provider: CloudProvider
    
    var body: some View {
        Text(text)
            .font(Design.Font.badge)
            .foregroundStyle(.white.opacity(0.95))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background {
                Capsule()
                    .fill(badgeColor)
            }
    }
    
    private var badgeColor: Color {
        switch provider {
        case .eks:
            return Design.Colors.badgeOrange
        case .gke:
            return Design.Colors.badgeBlue
        case .digitalocean:
            return Color(red: 0, green: 0.41, blue: 0.87)
        case .minikube, .kind, .k3d:
            return Design.Colors.badgePurple
        case .rancher:
            return Design.Colors.badgeTeal
        case .docker:
            return Design.Colors.badgeBlue
        case .other:
            return Design.Colors.textTertiary
        }
    }
}
