import SwiftUI

struct AppFlowView: View {
    private enum Stage {
        case loading
        case activity
        case search
    }

    @State private var stage = Stage.loading

    var body: some View {
        ZStack {
            switch stage {
            case .loading:
                LoaderView()
                    .transition(.opacity)
            case .activity:
                ActivityView {
                    stage = .search
                }
                .transition(.opacity)
            case .search:
                ContentView {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        stage = .activity
                    }
                }
                    .transition(.opacity)
            }
        }
        .background(Color.white)
        .preferredColorScheme(.light)
        .task {
            guard stage == .loading else { return }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.35)) {
                stage = .activity
            }
        }
    }
}

private struct LoaderView: View {
    @State private var isBreathing = false

    var body: some View {
        Image("TeamsLoader")
            .resizable()
            .frame(width: 36, height: 38)
            .frame(width: 48, height: 48)
            .scaleEffect(isBreathing ? 1.04 : 0.98)
            .opacity(isBreathing ? 1 : 0.84)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 0.72).repeatForever(autoreverses: true)) {
                    isBreathing = true
                }
            }
    }
}

#Preview {
    AppFlowView()
}