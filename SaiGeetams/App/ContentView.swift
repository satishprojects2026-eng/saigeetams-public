import SwiftUI

struct ContentView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(UIStore.self) private var uiStore
    @StateObject private var updateService = AppUpdateService.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            if updateService.updateRequired {
                // Block entire app -- update required
                ZStack {
                    AppSettings.Colors.teacherBg.ignoresSafeArea()
                    VStack(spacing: 20) {
                        Image(systemName: "arrow.down.app.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(AppSettings.Colors.teacherAccent)
                        Text("Update Required")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("A new version of \(AppSettings.appName) is available. The app will open the App Store for you.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        ThemedButton("Open App Store", color: AppSettings.Colors.teacherAccent, textColor: .black) {
                            updateService.openAppStore()
                        }
                        .padding(.horizontal, 32)
                    }
                }
            } else {
                Group {
                    if authStore.isLoading {
                        SplashView(authStore: authStore)
                    } else if !authStore.isAuthenticated {
                        NavigationStack {
                            RoleSelectView()
                        }
                    } else if !authStore.isOnboarded {
                        NavigationStack {
                            OnboardingView(role: authStore.role ?? .teacher)
                        }
                    } else {
                        switch authStore.role {
                        case .teacher:
                            TeacherTabView()
                        case .student:
                            StudentTabView()
                        default:
                            ParentTabView()
                        }
                    }
                }

                // Blocking ack modal at ROOT level
                if uiStore.pendingAckMessage != nil {
                    BlockingAckModal(uiStore: uiStore, authStore: authStore)
                }

                // Badge toast overlay
                if let toast = uiStore.badgeToast {
                    VStack {
                        BadgeToastView(icon: toast.icon, title: toast.title)
                            .padding(.top, 60)
                        Spacer()
                    }
                    .animation(.spring, value: uiStore.badgeToast != nil)
                }
            }
        }
        .task {
            await updateService.checkForUpdate()
            if !updateService.updateRequired {
                await NotificationService.shared.registerForPush()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await updateService.recheckOnForeground() }
            }
        }
    }
}

// MARK: - Teacher Tab View
struct TeacherTabView: View {
    var body: some View {
        TabView {
            NavigationStack { TeacherDashboardView() }
                .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack { TeacherCalendarView() }
                .tabItem { Label("Calendar", systemImage: "calendar") }

            NavigationStack { TeacherClassesView() }
                .tabItem { Label("Classes", systemImage: "books.vertical.fill") }

            NavigationStack { TeacherStudentsView() }
                .tabItem { Label("Students", systemImage: "person.2.fill") }
        }
        .tint(AppSettings.Colors.teacherAccent)
        .onAppear { configureTabBar(bg: AppSettings.Colors.teacherBg) }
    }
}

// MARK: - Student Tab View
struct StudentTabView: View {
    var body: some View {
        TabView {
            NavigationStack { StudentCalendarView() }
                .tabItem { Label("Calendar", systemImage: "calendar") }

            NavigationStack { StudentPracticeLogView() }
                .tabItem { Label("Practice", systemImage: "music.note") }

            NavigationStack { StudentProgressView() }
                .tabItem { Label("Progress", systemImage: "star.fill") }

            NavigationStack { StudentMessagesView() }
                .tabItem { Label("Messages", systemImage: "envelope.fill") }

            NavigationStack { StudentProfileView() }
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .tint(AppSettings.Colors.studentAccent)
        .onAppear { configureTabBar(bg: AppSettings.Colors.studentBg) }
    }
}

// MARK: - Parent Tab View
struct ParentTabView: View {
    var body: some View {
        TabView {
            NavigationStack { ParentDashboardView() }
                .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack { ParentScheduleView() }
                .tabItem { Label("Schedule", systemImage: "calendar") }

            NavigationStack { ParentProgressView() }
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
        }
        .tint(AppSettings.Colors.parentAccent)
        .onAppear { configureTabBar(bg: AppSettings.Colors.parentBg) }
    }
}

// MARK: - Tab bar appearance
private func configureTabBar(bg: Color) {
    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()
    appearance.backgroundColor = UIColor(bg)
    UITabBar.appearance().standardAppearance = appearance
    UITabBar.appearance().scrollEdgeAppearance = appearance
}
