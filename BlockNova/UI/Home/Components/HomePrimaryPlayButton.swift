import SwiftUI

struct HomePrimaryPlayButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("OYNA")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.88, blue: 0.42),
                                    Color(red: 0.0, green: 0.74, blue: 0.33),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(
                            color: Color(red: 0.0, green: 0.82, blue: 0.35)
                                .opacity(0.45),
                            radius: 20,
                            x: 0,
                            y: 12
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
