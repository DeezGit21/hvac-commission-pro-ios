import SwiftUI

// MARK: - Color Palette (mirrors Android theme/Color.kt)

extension Color {
    static let darkBg = Color(red: 0.043, green: 0.059, blue: 0.098)           // #0B0F19
    static let darkSurface = Color(red: 0.075, green: 0.106, blue: 0.180)      // #131B2E
    static let darkSurfaceElevated = Color(red: 0.106, green: 0.149, blue: 0.251) // #1B2640
    static let darkSurfaceBorder = Color(red: 0.137, green: 0.196, blue: 0.322) // #233252
    static let darkSurfaceHighlight = Color(red: 0.173, green: 0.243, blue: 0.400) // #2C3E66

    static let cyanAccent = Color(red: 0.220, green: 0.741, blue: 0.973)      // #38BDF8
    static let cyanDark = Color(red: 0.008, green: 0.518, blue: 0.780)         // #0284C7

    static let orangeFlame = Color(red: 0.976, green: 0.451, blue: 0.086)     // #F97316
    static let orangeDark = Color(red: 0.761, green: 0.251, blue: 0.047)      // #C2410C

    static let goldCommission = Color(red: 0.984, green: 0.749, blue: 0.141) // #FBBF24
    static let emeraldCompleted = Color(red: 0.063, green: 0.722, blue: 0.506) // #10B981
    static let rosePending = Color(red: 0.957, green: 0.247, blue: 0.369)      // #F43F5E
    static let purplePcp = Color(red: 0.659, green: 0.333, blue: 0.843)       // #A855F7

    static let textPrimary = Color(red: 0.973, green: 0.980, blue: 0.988)      // #F8FAFC
    static let textSecondary = Color(red: 0.580, green: 0.639, blue: 0.722)    // #94A3B8
    static let textMuted = Color(red: 0.392, green: 0.455, blue: 0.549)         // #64748B
    static let dividerColor = Color(red: 0.118, green: 0.161, blue: 0.231)     // #1E293B
}

// MARK: - App Theme

struct HVACCommissionTheme: ViewModifier {
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(.dark)
            .background(Color.darkBg.ignoresSafeArea())
            .tint(.cyanAccent)
    }
}

extension View {
    func hvacCommissionTheme() -> some View {
        modifier(HVACCommissionTheme())
    }
}

// MARK: - Helper: Currency Format

func formatMoney(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "en_US")
    return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
}

func formatMoneyNoDecimals(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "en_US")
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: amount)) ?? "$0"
}

// MARK: - Date Helpers

func formatDate(_ timestamp: Double, format: String = "MMM d, yyyy") -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    formatter.locale = Locale(identifier: "en_US")
    return formatter.string(from: Date(timeIntervalSince1970: timestamp / 1000))
}

func formatDateShort(_ timestamp: Double) -> String {
    formatDate(timestamp, format: "EEE, MMM d")
}
