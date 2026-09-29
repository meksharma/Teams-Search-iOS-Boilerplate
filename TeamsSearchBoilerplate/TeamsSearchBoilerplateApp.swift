import SwiftUI

@main
struct TeamsSearchBoilerplateApp: App {
    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.arguments.contains("--demo-zero-input") {
                DemoRecordingView(mode: .zeroInput)
            } else if ProcessInfo.processInfo.arguments.contains("--demo-filter-results") {
                DemoRecordingView(mode: .filterResults)
            } else if ProcessInfo.processInfo.arguments.contains("--portfolio-intro") {
                PortfolioIntroView()
            } else {
                AppFlowView()
            }
        }
    }
}