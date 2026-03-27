import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String?
    
    init(icon: String, title: String, subtitle: String? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Design.Colors.surface1)
                    .frame(width: 64, height: 64)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Design.Colors.textTertiary)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(Design.Font.headline)
                    .foregroundStyle(Design.Colors.textSecondary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Design.Font.caption)
                        .foregroundStyle(Design.Colors.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
