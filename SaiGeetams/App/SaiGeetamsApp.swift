import SwiftUI

@main
struct SaiGeetamsApp: App {
    @State private var authStore = AuthStore()
    @State private var classStore = ClassStore()
    @State private var uiStore = UIStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authStore)
                .environment(classStore)
                .environment(uiStore)
                .preferredColorScheme(.dark)
        }
    }
}
