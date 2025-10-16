import SwiftUI

struct GV_SplashHeaderTest: View {
    @ObservedObject private var themeManager = GV_Temas_Manager.shared
    private let myHeader: GV_HeaderType = .tipo1

    var body: some View {
        VStack(spacing: 0) {
            // Header oficial con menú de tipo splash
            myHeader.headerViewWithMenu("xxxxx", nil, .splash)

            Spacer()
        }
        .background(themeManager.background)
        .preferredColorScheme(themeManager.currentTheme.preferredColorScheme)
    }
}

#Preview {
    GV_SplashHeaderTest()
}


