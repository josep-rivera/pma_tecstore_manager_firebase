import SwiftUI

// ─────────────────────────────────────────────
// MARK: - BienvenidaView  (P01)
// Hosted in UIHostingController inside UINavigationController (hidden nav bar).
// Navigation is handled by SceneDelegate via callbacks — no NavigationStack needed.
// ─────────────────────────────────────────────

struct BienvenidaView: View {

    let onLogin:    () -> Void
    let onRegister: () -> Void

    var body: some View {
        ZStack {
            // Subtle gradient background
            LinearGradient(
                colors: [
                    Color.brandPrimary.opacity(0.10),
                    Color.brandLight.opacity(0.25),
                    Color(UIColor.appBackground)
                ],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ── Logo ──
                ZStack {
                    Circle()
                        .fill(Color.brandPrimary.opacity(0.12))
                        .frame(width: 130, height: 130)
                    Circle()
                        .fill(Color.brandPrimary.opacity(0.08))
                        .frame(width: 110, height: 110)
                    Image(systemName: "storefront.fill")
                        .font(.system(size: 56, weight: .semibold))
                        .foregroundColor(.brandPrimary)
                }

                Spacer().frame(height: 32)

                // ── App Name ──
                Text("TecStore Manager")
                    .font(.system(.largeTitle).bold())
                    .foregroundColor(.primary)

                Text("Gestiona productos, clientes\ny ventas de tu tienda")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
                    .padding(.horizontal, 40)

                Spacer()

                // ── Action Buttons ──
                VStack(spacing: 12) {
                    Button(action: onLogin) {
                        Text("Iniciar sesión")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: CGFloat(AppLayout.buttonHeight))
                            .background(Color.brandPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(CGFloat(AppLayout.cornerRadius))
                    }

                    Button(action: onRegister) {
                        Text("Crear cuenta")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: CGFloat(AppLayout.buttonHeight))
                            .background(Color.brandLight)
                            .foregroundColor(Color.brandPrimary)
                            .cornerRadius(CGFloat(AppLayout.cornerRadius))
                    }
                }
                .padding(.horizontal, CGFloat(AppLayout.paddingLarge))

                // ── Institution Footer ──
                Text("TECSUP · Desarrollo de Apps Móviles")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.appTextTertiary))
                    .padding(.top, 24)
                    .padding(.bottom, 44)
            }
        }
    }
}

#Preview {
    BienvenidaView(onLogin: {}, onRegister: {})
}
