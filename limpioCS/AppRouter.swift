import SwiftUI
import Combine   // <-- Necesario para ObservableObject y @Published

enum AppRoute: Hashable {
    case ccpWebServices
}

final class AppRouter: ObservableObject {
    @Published var path = NavigationPath()

    func go(_ route: AppRoute) { path.append(route) }
    func back() { if !path.isEmpty { path.removeLast() } }
    func reset() { path = NavigationPath() }
}
