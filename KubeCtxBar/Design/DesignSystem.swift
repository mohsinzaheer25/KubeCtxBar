import SwiftUI

// MARK: - Premium Design System

enum Design {
    
    // MARK: - Layout
    
    enum Layout {
        static let popoverWidth: CGFloat = 320
        static let popoverMinHeight: CGFloat = 240
        static let popoverMaxHeight: CGFloat = 480
        static let cornerRadius: CGFloat = 16
        static let innerRadius: CGFloat = 12
        static let rowRadius: CGFloat = 10
        static let padding: CGFloat = 16
        static let spacing: CGFloat = 12
    }
    
    // MARK: - Colors (OKLCH-based palette)
    
    enum Colors {
        // Primary colors from OKLCH (more accurate conversion)
        // oklch(84.1% 0.238 128.85) - Green (brighter, more saturated)
        static let green = Color(red: 60/255, green: 220/255, blue: 90/255)
        
        // oklch(85.2% 0.199 91.936) - Yellow
        static let yellow = Color(red: 250/255, green: 204/255, blue: 21/255)
        
        // oklch(58.6% 0.253 17.585) - Red
        static let red = Color(red: 239/255, green: 68/255, blue: 68/255)
        
        // oklch(71.4% 0.203 305.504) - Purple/Violet for icon
        static let iconPurple = Color(red: 167/255, green: 139/255, blue: 250/255)
        
        // Surface hierarchy - darker active state
        static let surface0 = Color(white: 0.06)  // Deepest background
        static let surface1 = Color(white: 0.10)  // Cards
        static let surface2 = Color(white: 0.14)  // Hover
        static let surface3 = Color(white: 0.22)  // Active highlight - DARKER
        
        // Text hierarchy
        static let textPrimary = Color.white.opacity(0.95)
        static let textSecondary = Color.white.opacity(0.6)
        static let textTertiary = Color.white.opacity(0.4)
        
        // Borders
        static let border = Color.white.opacity(0.08)
        static let borderHover = Color.white.opacity(0.15)
        static let borderActive = Color.white.opacity(0.3)
        
        // Badges
        static let badgeOrange = Color(red: 251/255, green: 146/255, blue: 60/255)
        static let badgeBlue = Color(red: 96/255, green: 165/255, blue: 250/255)
        static let badgePurple = Color(red: 167/255, green: 139/255, blue: 250/255)
        static let badgeTeal = Color(red: 45/255, green: 212/255, blue: 191/255)
    }
    
    // MARK: - Typography
    
    enum Font {
        static let title = SwiftUI.Font.system(size: 16, weight: .semibold, design: .default)
        static let headline = SwiftUI.Font.system(size: 14, weight: .semibold, design: .default)
        static let body = SwiftUI.Font.system(size: 13, weight: .medium, design: .default)
        static let secondary = SwiftUI.Font.system(size: 12, weight: .regular, design: .default)
        static let caption = SwiftUI.Font.system(size: 11, weight: .regular, design: .default)
        static let mono = SwiftUI.Font.system(size: 11, weight: .medium, design: .monospaced)
        static let badge = SwiftUI.Font.system(size: 10, weight: .bold, design: .default)
        static let sectionHeader = SwiftUI.Font.system(size: 11, weight: .semibold, design: .default)
    }
    
    // MARK: - Animation
    
    enum Animation {
        static let fast = SwiftUI.Animation.easeOut(duration: 0.12)
        static let smooth = SwiftUI.Animation.spring(response: 0.35, dampingFraction: 0.8)
        static let bounce = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
    }
}

// MARK: - Premium Glass Background

struct PremiumBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    // Base material
                    RoundedRectangle(cornerRadius: Design.Layout.cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // Dark overlay
                    RoundedRectangle(cornerRadius: Design.Layout.cornerRadius, style: .continuous)
                        .fill(Design.Colors.surface0.opacity(0.85))
                    
                    // Subtle border
                    RoundedRectangle(cornerRadius: Design.Layout.cornerRadius, style: .continuous)
                        .strokeBorder(Design.Colors.border, lineWidth: 0.5)
                }
            }
            .shadow(color: .black.opacity(0.3), radius: 30, y: 15)
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
    }
}

// MARK: - Card Background

struct CardBackground: ViewModifier {
    let isHovered: Bool
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .background {
                if isActive || isHovered {
                    ZStack {
                        RoundedRectangle(cornerRadius: Design.Layout.rowRadius, style: .continuous)
                            .fill(backgroundColor)
                        
                        RoundedRectangle(cornerRadius: Design.Layout.rowRadius, style: .continuous)
                            .strokeBorder(borderColor, lineWidth: isActive ? 1 : 0.5)
                    }
                }
            }
    }
    
    private var backgroundColor: Color {
        if isActive { return Design.Colors.surface1 } // Same as search box
        if isHovered { return Design.Colors.surface1.opacity(0.7) }
        return .clear
    }
    
    private var borderColor: Color {
        if isActive { return Design.Colors.borderActive }
        if isHovered { return Design.Colors.borderHover }
        return .clear
    }
}

// MARK: - View Extensions

extension View {
    func premiumBackground() -> some View {
        modifier(PremiumBackground())
    }
    
    func cardBackground(isHovered: Bool = false, isActive: Bool = false) -> some View {
        modifier(CardBackground(isHovered: isHovered, isActive: isActive))
    }
}
