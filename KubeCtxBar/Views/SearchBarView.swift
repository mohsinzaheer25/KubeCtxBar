import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Design.Colors.textTertiary)
            
            TextField("Search contexts...", text: $text)
                .textFieldStyle(.plain)
                .font(Design.Font.body)
                .foregroundStyle(Design.Colors.textPrimary)
                .focused(isFocused)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Design.Colors.textTertiary)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: Design.Layout.innerRadius, style: .continuous)
                .fill(Design.Colors.surface1)
                .overlay {
                    RoundedRectangle(cornerRadius: Design.Layout.innerRadius, style: .continuous)
                        .strokeBorder(Design.Colors.border, lineWidth: 0.5)
                }
        }
    }
}
