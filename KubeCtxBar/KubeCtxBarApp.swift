import SwiftUI

@main
struct KubeCtxBarApp: App {
    @StateObject private var viewModel = ContextListViewModel()
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarPopover(viewModel: viewModel)
        } label: {
            MenuBarIcon(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Menu Bar Icon

struct MenuBarIcon: View {
    @ObservedObject var viewModel: ContextListViewModel
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 14, weight: .medium))
                .rotationEffect(.degrees(rotation))
            
            // Error indicator
            if viewModel.errorMessage != nil {
                Circle()
                    .fill(.red)
                    .frame(width: 6, height: 6)
                    .offset(x: 6, y: -6)
            }
        }
        .help("KubeCtx")
        .onChange(of: viewModel.isSwitching) { _, switching in
            if switching {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    rotation = 0
                }
            }
        }
    }
}
