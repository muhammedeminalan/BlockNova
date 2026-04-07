import SwiftUI

struct InGameHUDView: View {
    let onHomeTap: () -> Void

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                HStack {
                    Button(action: onHomeTap) {
                        HStack(spacing: 6) {
                            Image(systemName: "house.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("Ana Menu")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white.opacity(0.92))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.32))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, max(10, proxy.safeAreaInsets.top + 2))

                Spacer()
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    InGameHUDView(onHomeTap: {})
}
