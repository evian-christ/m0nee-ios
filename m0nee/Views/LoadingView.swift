import SwiftUI

struct LoadingView: View {
    @EnvironmentObject var settings: AppSettings
    @Environment(\.colorScheme) var colorScheme

    private var preferredScheme: ColorScheme? {
        switch settings.appearanceMode {
        case "Light":
            return .light
        case "Dark":
            return .dark
        default:
            return nil
        }
    }

    private var isDarkMode: Bool {
        if let scheme = preferredScheme {
            return scheme == .dark
        }
        return colorScheme == .dark
    }

    var body: some View {
        ZStack {
            // 테마에 맞는 배경
            if isDarkMode {
                Color.black
                    .ignoresSafeArea()
            } else {
                Color.white
                    .ignoresSafeArea()
            }

            VStack(spacing: 24) {
                // 실제 앱 아이콘 (다크모드 자동 대응)
                Image("AppIconImage")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .cornerRadius(26.4)

                // 로딩 인디케이터
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.2)
            }
        }
        .preferredColorScheme(preferredScheme)
    }
}
