import SwiftUI

struct MenuBarPopover: View {
    @ObservedObject var viewModel: ContextListViewModel
    @State private var selectedIndex: Int?
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        Group {
            if viewModel.showSettings {
                SettingsView(viewModel: viewModel)
            } else {
                mainContent
            }
        }
        .frame(width: Design.Layout.popoverWidth)
        .frame(minHeight: Design.Layout.popoverMinHeight, maxHeight: Design.Layout.popoverMaxHeight)
        .premiumBackground()
        .animation(Design.Animation.smooth, value: viewModel.showSettings)
        .onKeyPress(.escape) {
            if viewModel.showSettings { viewModel.showSettings = false; return .handled }
            return .ignored
        }
        .onKeyPress(.upArrow) { navigate(-1); return .handled }
        .onKeyPress(.downArrow) { navigate(1); return .handled }
        .onKeyPress(.return) { activate(); return .handled }
        .onKeyPress(characters: CharacterSet(charactersIn: "/")) { _ in isSearchFocused = true; return .handled }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            headerSection
            searchSection
            dividerLine
            contentSection
            if let error = viewModel.errorMessage { errorSection(error) }
            footerDivider
            footerSection
        }
    }
    
    // MARK: - Header (purple icon, no background)
    
    private var headerSection: some View {
        HStack(spacing: 10) {
            // App icon - purple color, transparent background, smaller
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Design.Colors.iconPurple)
            
            // App name
            Text("KubeCtx")
                .font(Design.Font.title)
                .foregroundStyle(Design.Colors.textPrimary)
            
            Spacer()
            
            // Current context in a box on the right
            if let current = viewModel.currentContext {
                Text(extractDisplayName(current))
                    .font(Design.Font.mono)
                    .foregroundStyle(Design.Colors.green)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Design.Colors.surface1)
                            .overlay {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(Design.Colors.border, lineWidth: 0.5)
                            }
                    }
            }
        }
        .padding(Design.Layout.padding)
    }
    
    private func extractDisplayName(_ name: String) -> String {
        if name.contains("arn:aws:eks") {
            return name.components(separatedBy: "/").last ?? name
        }
        if name.contains("gke_") {
            let parts = name.components(separatedBy: "_")
            if parts.count >= 4 { return parts[3] }
        }
        return name
    }
    
    // MARK: - Search
    
    private var searchSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Design.Colors.textTertiary)
            
            TextField("Search contexts...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .font(Design.Font.body)
                .foregroundStyle(Design.Colors.textPrimary)
                .focused($isSearchFocused)
            
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
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
        .padding(.horizontal, Design.Layout.padding)
        .padding(.bottom, Design.Layout.spacing)
    }
    
    // MARK: - Dividers
    
    private var dividerLine: some View {
        Rectangle()
            .fill(Design.Colors.border)
            .frame(height: 0.5)
            .padding(.horizontal, Design.Layout.padding)
    }
    
    private var footerDivider: some View {
        Rectangle()
            .fill(Design.Colors.border)
            .frame(height: 0.5)
    }
    
    // MARK: - Content
    
    private var contentSection: some View {
        Group {
            if viewModel.isLoading {
                loadingState
            } else if viewModel.filteredContexts.isEmpty {
                emptyState
            } else {
                contextList
            }
        }
    }
    
    private var loadingState: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(0.9)
                .tint(Design.Colors.iconPurple)
            Text("Loading contexts...")
                .font(Design.Font.secondary)
                .foregroundStyle(Design.Colors.textSecondary)
            Spacer()
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Design.Colors.surface1)
                    .frame(width: 64, height: 64)
                
                Image(systemName: viewModel.searchText.isEmpty ? "tray" : "magnifyingglass")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Design.Colors.textTertiary)
            }
            
            VStack(spacing: 4) {
                Text(viewModel.searchText.isEmpty ? "No Contexts Found" : "No Results")
                    .font(Design.Font.headline)
                    .foregroundStyle(Design.Colors.textSecondary)
                
                Text(viewModel.searchText.isEmpty ? "Check your kubeconfig file" : "Try a different search")
                    .font(Design.Font.caption)
                    .foregroundStyle(Design.Colors.textTertiary)
            }
            
            Spacer()
        }
    }
    
    private var contextList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(Array(viewModel.filteredContexts.enumerated()), id: \.element.id) { index, context in
                        ContextRowView(
                            context: context,
                            isActive: context.name == viewModel.currentContext,
                            isSelected: selectedIndex == index,
                            isFlashing: context.name == viewModel.recentlySwitchedContext
                        ) {
                            Task { await viewModel.switchTo(context) }
                        }
                        .id(context.id)
                    }
                }
                .padding(10)
            }
            .onChange(of: viewModel.currentContext) { _, newContext in
                if let newContext = newContext,
                   let firstContext = viewModel.filteredContexts.first,
                   firstContext.name == newContext {
                    withAnimation {
                        proxy.scrollTo(firstContext.id, anchor: .top)
                    }
                }
            }
        }
    }
    
    // MARK: - Error
    
    private func errorSection(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Design.Colors.red)
            
            Text(message)
                .font(Design.Font.caption)
                .foregroundStyle(Design.Colors.textPrimary)
                .lineLimit(2)
            
            Spacer()
            
            Button { viewModel.dismissError() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Design.Colors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Design.Colors.red.opacity(0.15))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Design.Colors.red.opacity(0.3), lineWidth: 0.5)
                }
        }
        .padding(.horizontal, Design.Layout.padding)
        .padding(.bottom, 10)
    }
    
    // MARK: - Footer
    
    private var footerSection: some View {
        HStack(spacing: 0) {
            FooterButton(icon: "arrow.clockwise", label: "Refresh") {
                Task { await viewModel.refresh() }
            }
            
            Spacer()
            
            FooterButton(icon: "gearshape.fill", label: "Settings") {
                viewModel.showSettings = true
            }
            
            Spacer()
            
            FooterButton(icon: "power", label: "Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.horizontal, Design.Layout.padding + 8)
        .padding(.vertical, 14)
    }
    
    // MARK: - Navigation
    
    private func navigate(_ direction: Int) {
        let count = viewModel.filteredContexts.count
        guard count > 0 else { return }
        selectedIndex = selectedIndex == nil
            ? (direction > 0 ? 0 : count - 1)
            : ((selectedIndex! + direction + count) % count)
    }
    
    private func activate() {
        guard let index = selectedIndex, index < viewModel.filteredContexts.count else { return }
        Task { await viewModel.switchTo(viewModel.filteredContexts[index]) }
    }
}

// MARK: - Footer Button

struct FooterButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(isPressed ? Design.Colors.surface3 : (isHovered ? Design.Colors.surface2 : Design.Colors.surface1))
                        .frame(width: 36, height: 36)
                    
                    Circle()
                        .strokeBorder(isHovered ? Design.Colors.borderHover : Design.Colors.border, lineWidth: 0.5)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isHovered ? Design.Colors.textPrimary : Design.Colors.textSecondary)
                }
                .scaleEffect(isPressed ? 0.92 : 1)
                
                Text(label)
                    .font(Design.Font.caption)
                    .foregroundStyle(isHovered ? Design.Colors.textSecondary : Design.Colors.textTertiary)
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(Design.Animation.fast) { isPressed = true } }
                .onEnded { _ in withAnimation(Design.Animation.fast) { isPressed = false } }
        )
        .animation(Design.Animation.fast, value: isHovered)
    }
}
