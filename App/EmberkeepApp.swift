import SwiftUI

@main
struct EmberkeepApp: App {
    var body: some Scene {
        WindowGroup { GameScreen() }
        #if os(macOS)
        .defaultSize(width: 1200, height: 800)
        .windowStyle(.hiddenTitleBar)
        #endif
    }
}
