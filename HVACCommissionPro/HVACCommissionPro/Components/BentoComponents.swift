import SwiftUI

// MARK: - Bento Card

struct BentoCard<Content: View>: View {
    let backgroundColor: Color
    let borderColor: Color
    let borderWidth: CGFloat
    let onClick: (() -> Void)?
    let content: Content

    init(
        backgroundColor: Color = .darkSurface,
        borderColor: Color = .darkSurfaceBorder,
        borderWidth: CGFloat = 1,
        onClick: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.onClick = onClick
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            onClick?()
        }
    }
}

// MARK: - Bento Metric Tile

struct BentoMetricTile: View {
    let title: String
    let value: String
    let subtitle: String
    let systemImage: String?
    let valueColor: Color
    let accentColor: Color
    let onClick: (() -> Void)?

    init(title: String, value: String, subtitle: String, systemImage: String? = nil, valueColor: Color = .textPrimary, accentColor: Color = .cyanAccent, onClick: (() -> Void)? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.valueColor = valueColor
        self.accentColor = accentColor
        self.onClick = onClick
    }

    var body: some View {
        BentoCard(backgroundColor: .darkSurface, borderColor: .darkSurfaceBorder, onClick: onClick) {
            HStack {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.textSecondary)
                    .tracking(0.5)
                Spacer()
                if let img = systemImage {
                    Image(systemName: img)
                        .font(.system(size: 14))
                        .foregroundColor(accentColor)
                }
            }
            Spacer().frame(height: 6)
            Text(value)
                .font(.system(size: 22, weight: .black))
                .foregroundColor(valueColor)
            Spacer().frame(height: 2)
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(.textMuted)
        }
    }
}

// MARK: - Bento Action Tile

struct BentoActionTile: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let accentColor: Color
    let onClick: () -> Void

    var body: some View {
        BentoCard(backgroundColor: .darkSurface, borderColor: .darkSurfaceBorder, onClick: onClick) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 20))
                    .foregroundColor(accentColor)
                    .frame(width: 38, height: 38)
                    .background(accentColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Spacer().frame(width: 10)
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Commission Type Badge

struct CommissionTypeBadge: View {
    let typeTag: CommissionTypeTag

    var body: some View {
        let (bg, fg): (Color, Color) = {
            switch typeTag {
            case .soldOnlyThisWeek: return (.cyanAccent.opacity(0.15), .cyanAccent)
            case .completedCarryover: return (.emeraldCompleted.opacity(0.15), .emeraldCompleted)
            case .sameWeekFull: return (.goldCommission.opacity(0.2), .goldCommission)
            case .unitSale: return (.orangeFlame.opacity(0.2), .orangeFlame)
            case .customRate: return (.textSecondary.opacity(0.2), .textSecondary)
            }
        }()

        Text(typeTag.label)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Job Type Badge

struct JobTypeBadge: View {
    let jobType: JobType

    var body: some View {
        let (bg, fg): (Color, Color) = {
            switch jobType {
            case .standardJob: return (.cyanAccent.opacity(0.15), .cyanAccent)
            case .unitSale: return (.orangeFlame.opacity(0.2), .orangeFlame)
            case .custom: return (.goldCommission.opacity(0.2), .goldCommission)
            }
        }()

        Text(jobType.label)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let isCompleted: Bool

    var body: some View {
        let bg = isCompleted ? Color.emeraldCompleted.opacity(0.15) : Color.rosePending.opacity(0.15)
        let fg = isCompleted ? Color.emeraldCompleted : Color.rosePending
        let label = isCompleted ? "Completed" : "In-Progress"

        Text(label)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Telemetry Mini Box

struct TelemetryMiniBox: View {
    let title: String
    let value: String
    let evaluation: String
    let isNormal: Bool

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.textSecondary)
            Text(value)
                .font(.system(size: 16, weight: .black))
                .foregroundColor(isNormal ? .emeraldCompleted : .orangeFlame)
            if !evaluation.isEmpty {
                Text(evaluation)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(isNormal ? .emeraldCompleted : .orangeFlame)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.darkBg)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isNormal ? Color.emeraldCompleted.opacity(0.3) : Color.orangeFlame.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Commission Rule Row

struct CommissionRuleRow: View {
    let ruleTitle: String
    let ruleDesc: String
    let amount: String
    let accentColor: Color

    var body: some View {
        HStack {
            Circle()
                .fill(accentColor)
                .frame(width: 8, height: 8)
            Spacer().frame(width: 10)
            VStack(alignment: .leading) {
                Text(ruleTitle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.textPrimary)
                Text(ruleDesc)
                    .font(.system(size: 10))
                    .foregroundColor(.textMuted)
            }
            Spacer()
            Text(amount)
                .font(.system(size: 14, weight: .black))
                .foregroundColor(accentColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.darkBg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Styled Text Field

struct StyledTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var leadingIcon: String? = nil

    var body: some View {
        HStack {
            if let icon = leadingIcon {
                Image(systemName: icon)
                    .foregroundColor(.cyanAccent)
                    .font(.system(size: 16))
            }
            TextField(title, text: $text, prompt: Text(placeholder).foregroundColor(.textMuted))
                .foregroundColor(.textPrimary)
                .keyboardType(keyboardType)
        }
        .padding(12)
        .background(Color.darkBg)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.darkSurfaceBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Scanned Row

struct ScannedRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.textPrimary)
        }
        .padding(.vertical, 3)
    }
}
