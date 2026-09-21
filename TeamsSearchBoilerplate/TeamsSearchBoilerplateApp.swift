import SwiftUI

@main
struct TeamsSearchBoilerplateApp: App {
    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.arguments.contains("--portfolio-intro") {
                PortfolioIntroView()
            } else {
                AppFlowView()
            }
        }
    }
}