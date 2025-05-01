// MARK: - Unified Navigation System

import SwiftUI
import Firebase
import Combine

// MARK: NavDestination Enum
enum NavDestination: Hashable {
    case home
    case profile
    case newPost
    case logRound
    case trips
    case career
    case register
    case login
    case uploadScorecard
}

// MARK: NavigationRouter using NavDestination
class NavigationRouter: ObservableObject {
    @Published var path: [NavDestination] = []

    func resetToHome() {
        path = []
    }

    func go(to route: NavDestination) {
        path.append(route)
    }
}

// MARK: Root App
@main
struct Golftripv2App: App {
    @StateObject var authViewModel = AuthViewModel()
    @StateObject var router = NavigationRouter()

    init() {
        FirebaseService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isLoggedIn {
                    NavigationStack(path: $router.path) {
                        TabView {
                            HomePageView()
                                .tabItem {
                                    Label("Home", systemImage: "house")
                                }

                            CareerView()
                                .tabItem {
                                    Label("Career", systemImage: "chart.bar")
                                }

                            TripsView()
                                .tabItem {
                                    Label("Trips", systemImage: "flag")
                                }
                        }
                        .navigationDestination(for: NavDestination.self) { route in
                            switch route {
                            case .home:
                                HomePageView()
                            case .career:
                                CareerView()
                            case .trips:
                                TripsView()
                            case .profile:
                                ProfileView()
                                    .environmentObject(authViewModel)
                            case .logRound:
                                LogRoundView()
                            case .newPost:
                                NewPostView()
                            case .register:
                                RegisterView()
                            case .login:
                                LoginView()
                            case .uploadScorecard:
                                ScorecardUploadView()
                            }
                        }
                    }
                } else {
                    NavigationStack(path: $router.path) {
                        LoginView()
                            .navigationDestination(for: NavDestination.self) { route in
                                switch route {
                                case .register:
                                    RegisterView()
                                case .login:
                                    LoginView()
                                default:
                                    EmptyView()
                                }
                            }
                    }
                }
            }
            .accentColor(Color("AppPrimary"))
            .environmentObject(authViewModel)
            .environmentObject(router)
        }
    }
}
