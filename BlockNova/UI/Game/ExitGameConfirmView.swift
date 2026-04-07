import SwiftUI

struct ExitGameConfirmView: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)

            VStack(spacing: 14) {
                Text("Oyundan Çık")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(.white)

                Text("Oyunu kaydedip Ana Menu'ye donmek istiyor musun?")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)

                VStack(spacing: 10) {
                    Button(action: onConfirm) {
                        Text("Kaydet ve Cik")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 14,
                                    style: .continuous
                                )
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(
                                                red: 0.00,
                                                green: 0.82,
                                                blue: 0.35
                                            ),
                                            Color(
                                                red: 0.00,
                                                green: 0.68,
                                                blue: 0.30
                                            ),
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: onCancel) {
                        Text("Iptal")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.86))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(
                                RoundedRectangle(
                                    cornerRadius: 12,
                                    style: .continuous
                                )
                                .fill(Color.white.opacity(0.10))
                                .overlay(
                                    RoundedRectangle(
                                        cornerRadius: 12,
                                        style: .continuous
                                    )
                                    .stroke(
                                        Color.white.opacity(0.18),
                                        lineWidth: 1
                                    )
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        Color(red: 0.07, green: 0.08, blue: 0.19).opacity(0.98)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
        }
    }
}

#Preview {
    ExitGameConfirmView(onCancel: {}, onConfirm: {})
}
