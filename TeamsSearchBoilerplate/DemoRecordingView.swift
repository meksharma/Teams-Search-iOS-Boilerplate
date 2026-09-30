import SwiftUI

struct DemoRecordingView: View {
    enum Mode {
        case zeroInput
        case filterResults
    }

    let mode: Mode

    @State private var showsSearch = false
    @State private var pressesSearch = false

    var body: some View {
        ZStack {
            if showsSearch {
                searchView
                    .transition(.opacity)
            } else {
                ActivityView(
                    onSearch: openSearch,
                    isSearchPressed: pressesSearch
                )
                .transition(.opacity)
            }
        }
        .background(Color.white)
        .preferredColorScheme(.light)
        .task {
            guard mode == .zeroInput else {
                showsSearch = true
                return
            }

            try? await Task.sleep(nanoseconds: 2_400_000_000)
            guard !Task.isCancelled else { return }
            pressesSearch = true
            try? await Task.sleep(nanoseconds: 140_000_000)
            guard !Task.isCancelled else { return }
            openSearch()
        }
    }

    @ViewBuilder
    private var searchView: some View {
        switch mode {
        case .zeroInput:
            ContentView(onDismiss: {})
        case .filterResults:
            ContentView(
                automatedQuery: "summ",
                automatedFilterTitles: ["People", "Messages", "Channels"],
                onDismiss: {}
            )
        }
    }

    private func openSearch() {
        withAnimation(.easeInOut(duration: 0.24)) {
            showsSearch = true
        }
    }
}
