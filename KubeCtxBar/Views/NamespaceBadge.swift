import SwiftUI

struct NamespaceBadge: View {
    let namespace: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "folder.fill")
                .font(.system(size: 8, weight: .medium))
            
            Text(namespace)
                .font(Design.Font.badge)
        }
        .foregroundStyle(.white.opacity(0.9))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 99/255, green: 102/255, blue: 241/255),
                            Color(red: 129/255, green: 140/255, blue: 248/255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
}
