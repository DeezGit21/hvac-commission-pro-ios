import SwiftUI
import SwiftData

@main
struct HVACCommissionProApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .hvacCommissionTheme()
                .modelContainer(for: HvacJob.self)
        }
    }
}
