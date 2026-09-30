import SwiftUI

struct PortfolioIntroView: View {
    private enum Stage {
        case loading
        case activity
        case search
    }

    @State private var stage = Stage.loading
    @State private var runID = 0

    var body: some View {
        ZStack {
            switch stage {
            case .loading:
                LoaderView()
                    .transition(.opacity)
            case .activity:
                ActivityView(onSearch: {})
                    .allowsHitTesting(false)
                    .transition(.opacity)
            case .search:
                ContentView(automatedQuery: "summ", onDismiss: {})
                    .id(runID)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .background(Color.white)
        .preferredColorScheme(.light)
        .task {
            while !Task.isCancelled {
                stage = .loading
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard !Task.isCancelled else { return }

                withAnimation(.easeInOut(duration: 0.35)) {
                    stage = .activity
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }

                runID += 1
                withAnimation(.easeInOut(duration: 0.35)) {
                    stage = .search
                }
                try? await Task.sleep(nanoseconds: 5_200_000_000)
                guard !Task.isCancelled else { return }

                withAnimation(.easeInOut(duration: 0.35)) {
                    stage = .loading
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }
}

#Preview {
    PortfolioIntroView()
}