import SwiftUI

// MARK: - Themed Card
struct ThemedCard<Content: View>: View {
    let bgColor: Color
    @ViewBuilder let content: () -> Content

    init(bgColor: Color = Color.white.opacity(0.08), @ViewBuilder content: @escaping () -> Content) {
        self.bgColor = bgColor
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content()
        }
        .padding(16)
        .background(bgColor)
        .cornerRadius(16)
    }
}

// MARK: - Themed Button
struct ThemedButton: View {
    let title: String
    let color: Color
    let textColor: Color
    let isLoading: Bool
    let disabled: Bool
    let action: () -> Void

    init(_ title: String, color: Color = AppSettings.Colors.teacherAccent, textColor: Color = .white,
         isLoading: Bool = false, disabled: Bool = false, action: @escaping () -> Void) {
        self.title = title; self.color = color; self.textColor = textColor
        self.isLoading = isLoading; self.disabled = disabled; self.action = action
    }

    var body: some View {
        Button {
            SoundService.shared.playNavigationSound()
            action()
        } label: {
            Group {
                if isLoading {
                    ProgressView().tint(textColor)
                } else {
                    Text(title).fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(textColor)
            .background(color)
            .cornerRadius(12)
        }
        .disabled(disabled || isLoading)
        .opacity(disabled ? 0.5 : 1)
    }
}

// MARK: - Ghost Button
struct GhostButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            SoundService.shared.playNavigationSound()
            action()
        } label: {
            Text(title)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, minHeight: 44)
        }
    }
}

// MARK: - Outline Button
struct OutlineButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button {
            SoundService.shared.playNavigationSound()
            action()
        } label: {
            Text(title)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, minHeight: 48)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(color, lineWidth: 2))
        }
    }
}

// MARK: - Themed Input
struct ThemedInput: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var accentColor: Color = AppSettings.Colors.teacherAccent
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var error: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(accentColor)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.06))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(error != nil ? Color.red : Color.white.opacity(0.2), lineWidth: 1.5))
            .foregroundStyle(.white)
            .autocorrectionDisabled()

            if let error {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Help Header
struct AppHeader: View {
    let title: String
    var bgColor: Color = AppSettings.Colors.teacherBg
    var textColor: Color = AppSettings.Colors.teacherAccent
    var onHelp: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.title2).bold()
                .foregroundStyle(textColor)
            Spacer()
            if let onHelp {
                Button {
                    SoundService.shared.playNavigationSound()
                    onHelp()
                } label: {
                    Image(systemName: "questionmark.circle")
                        .font(.title3)
                        .foregroundStyle(textColor)
                        .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Swara Ticker
struct SwaraTicker: View {
    @State private var offset: CGFloat = 300

    var body: some View {
        GeometryReader { geo in
            Text(AppSettings.swaraSequence.joined(separator: "  ") + "    " + AppSettings.swaraSequence.joined(separator: "  "))
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(AppSettings.Colors.studentAccent.opacity(0.6))
                .tracking(4)
                .offset(x: offset)
                .onAppear {
                    withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                        offset = -geo.size.width
                    }
                }
        }
        .frame(height: 32)
        .clipped()
    }
}

// MARK: - Skill Bar
struct SkillBarView: View {
    let skillName: String
    let level: Int
    var maxLevel: Int = 5
    var readOnly: Bool = false
    var onLevelChange: ((Int) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(skillName).font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                Spacer()
                Text(level < AppSettings.skillLevels.count ? AppSettings.skillLevels[level] : "")
                    .font(.caption).foregroundStyle(.white.opacity(0.6))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule().fill(AppSettings.Colors.teacherAccent)
                        .frame(width: geo.size.width * CGFloat(level) / CGFloat(maxLevel))
                }
            }
            .frame(height: 8)

            if !readOnly {
                HStack(spacing: 4) {
                    ForEach(1...maxLevel, id: \.self) { i in
                        Button {
                            SoundService.shared.playNavigationSound()
                            onLevelChange?(i)
                        } label: {
                            Image(systemName: i <= level ? "star.fill" : "star")
                                .foregroundStyle(i <= level ? AppSettings.Colors.teacherAccent : .white.opacity(0.3))
                                .frame(minWidth: 44, minHeight: 44)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Badge Grid
struct BadgeGridView: View {
    let earnedBadgeIds: Set<String>

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(AppSettings.badgeDefinitions) { badge in
                let isEarned = earnedBadgeIds.contains(badge.id)
                VStack(spacing: 6) {
                    Text(badge.icon).font(.system(size: 36))
                    Text(badge.title)
                        .font(.caption2).fontWeight(.semibold)
                        .foregroundStyle(isEarned ? AppSettings.Colors.studentAccent : .white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .background(isEarned ? AppSettings.Colors.studentAccent.opacity(0.15) : Color.white.opacity(0.05))
                .cornerRadius(16)
                .opacity(isEarned ? 1 : 0.4)
            }
        }
    }
}

// MARK: - Blocking Ack Modal
struct BlockingAckModal: View {
    @Bindable var uiStore: UIStore
    let authStore: AuthStore

    var body: some View {
        if let msg = uiStore.pendingAckMessage {
            ZStack {
                AppSettings.Colors.studentBg.ignoresSafeArea()
                VStack(spacing: 16) {
                    Text(msg.type.rawValue.uppercased())
                        .font(.caption).fontWeight(.bold).tracking(2)
                        .foregroundStyle(AppSettings.Colors.studentAccent)
                    if let title = msg.title {
                        Text(title).font(.title2).bold().foregroundStyle(.white).multilineTextAlignment(.center)
                    }
                    Text(msg.content)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    ThemedButton("OK", color: AppSettings.Colors.studentPrimary) {
                        Task {
                            if let userId = authStore.user?.id {
                                struct Ack: Encodable { let message_id: UUID; let student_id: UUID; let response: String }
                                try? await SupabaseService.shared.upsert("message_responses", value: Ack(
                                    message_id: msg.id, student_id: userId, response: "acknowledged"
                                ))
                            }
                            uiStore.pendingAckMessage = nil
                        }
                    }
                    .padding(.top, 16)
                }
                .padding(32)
                .background(Color.white.opacity(0.08))
                .cornerRadius(24)
                .padding(32)
            }
        }
    }
}

// MARK: - Badge Toast
struct BadgeToastView: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Text(icon).font(.largeTitle)
            Text(title).font(.headline).foregroundStyle(.black)
        }
        .padding(16)
        .background(AppSettings.Colors.studentAccent.opacity(0.95))
        .cornerRadius(16)
        .shadow(radius: 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
