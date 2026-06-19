import SwiftUI
import Combine
import PhotosUI

// ─────────────────────────────────────────────
// MARK: - PerfilViewModel
// ─────────────────────────────────────────────

@MainActor
final class PerfilViewModel: ObservableObject {

    @Published var user:           Usuario? = nil
    @Published var isDarkMode:     Bool     = UserDefaults.standard.bool(forKey: UserDefaultsKeys.darkModeEnabled)
    @Published var profileImage:   UIImage? = nil

    // Password change state
    @Published var currentPwd:  String = ""
    @Published var newPwd:      String = ""
    @Published var confirmPwd:  String = ""
    @Published var pwdError:    String = ""
    @Published var pwdSuccess:  Bool   = false

    // Alerts
    @Published var showLogoutAlert:  Bool   = false
    @Published var showErrorAlert:   Bool   = false
    @Published var errorMessage:     String = ""

    func loadUser() {
        user = AuthService.shared.currentUser
        if let path = user?.profileImagePath {
            profileImage = UIImage.fromDocuments(named: path)
        }
    }

    func toggleDarkMode() {
        SceneDelegate.shared?.setDarkMode(isDarkMode)
    }

    func saveProfilePhoto(_ image: UIImage) {
        let resized    = image.resized(maxDimension: 600)
        let fileName   = "profile_\(user?.id.compact ?? "unknown").jpg"
        let savedPath  = resized.saveToDocuments(named: fileName)
        profileImage   = resized
        AuthService.shared.updateProfile(fullName: user?.fullName ?? "", photoPath: savedPath)
        loadUser()
    }

    func changePassword() {
        pwdError = ""
        guard newPwd.count >= 6 else {
            pwdError = "La nueva contraseña debe tener al menos 6 caracteres."
            return
        }
        guard newPwd == confirmPwd else {
            pwdError = "Las contraseñas no coinciden."
            return
        }
        do {
            try AuthService.shared.changePassword(current: currentPwd, new: newPwd)
            pwdSuccess  = true
            currentPwd  = ""
            newPwd      = ""
            confirmPwd  = ""
        } catch let error as ServiceError {
            pwdError = error.errorDescription ?? "Error al cambiar contraseña."
        } catch {
            pwdError = error.localizedDescription
        }
    }

    func logout() {
        AuthService.shared.logout()
    }

    var userInitial: String {
        String(user?.fullName.prefix(1) ?? "?").uppercased()
    }
}

// ─────────────────────────────────────────────
// MARK: - PerfilView  (P16)
// ─────────────────────────────────────────────

struct PerfilView: View {

    @StateObject private var viewModel    = PerfilViewModel()
    @State private var showChangePassword = false
    @State private var selectedPhoto:     PhotosPickerItem? = nil

    var body: some View {
        Form {

            // ── Avatar + Info ──
            Section {
                HStack(spacing: 16) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        avatarView
                    }
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task {
                            if let data   = try? await newItem?.loadTransferable(type: Data.self),
                               let image  = UIImage(data: data) {
                                viewModel.saveProfilePhoto(image)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.user?.fullName ?? "Usuario")
                            .font(.headline)
                        Text(viewModel.user?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Registrado: \(viewModel.user?.registrationDate.displayDate ?? "")")
                            .font(.caption)
                            .foregroundColor(Color(UIColor.appTextTertiary))
                    }
                }
                .padding(.vertical, 4)
            }

            // ── Preferencias ──
            Section("Preferencias") {
                Toggle(isOn: $viewModel.isDarkMode) {
                    Label("Modo oscuro", systemImage: "moon.fill")
                }
                .tint(.brandPrimary)
                .onChange(of: viewModel.isDarkMode) { _, _ in
                    viewModel.toggleDarkMode()
                }
            }

            // ── Seguridad ──
            Section("Seguridad") {
                Button {
                    showChangePassword = true
                } label: {
                    Label("Cambiar contraseña", systemImage: "lock.rotation")
                        .foregroundColor(.primary)
                }
            }

            // ── App Info ──
            Section("Acerca de la app") {
                NavigationLink(destination: AcercaDeView()) {
                    Label("Acerca de TecStore Manager", systemImage: "info.circle")
                }
            }

            // ── Sesión ──
            Section {
                Button(role: .destructive) {
                    viewModel.showLogoutAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        // Change password sheet
        .sheet(isPresented: $showChangePassword) {
            CambiarPasswordSheet(viewModel: viewModel)
        }
        // Logout confirmation
        .alert("Cerrar sesión", isPresented: $viewModel.showLogoutAlert) {
            Button("Cancelar", role: .cancel) {}
            Button("Cerrar sesión", role: .destructive) { viewModel.logout() }
        } message: {
            Text("¿Estás seguro de que quieres cerrar sesión?")
        }
        .onAppear { viewModel.loadUser() }
    }

    // ── Avatar View ──
    private var avatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let img = viewModel.profileImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Circle()
                        .fill(Color.brandLight)
                        .overlay {
                            Text(viewModel.userInitial)
                                .font(.system(.title).bold())
                                .foregroundColor(.brandPrimary)
                        }
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.brandLight, lineWidth: 2))

            // Edit badge
            Image(systemName: "camera.fill")
                .font(.caption2)
                .foregroundColor(.white)
                .padding(5)
                .background(Color.brandPrimary)
                .clipShape(Circle())
                .offset(x: 2, y: 2)
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - CambiarPasswordSheet
// ─────────────────────────────────────────────

struct CambiarPasswordSheet: View {

    @ObservedObject var viewModel: PerfilViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("Contraseña actual", text: $viewModel.currentPwd)
                    SecureField("Nueva contraseña", text: $viewModel.newPwd)
                    SecureField("Confirmar nueva contraseña", text: $viewModel.confirmPwd)
                } footer: {
                    if !viewModel.pwdError.isEmpty {
                        Text(viewModel.pwdError)
                            .foregroundColor(.appError)
                    }
                    if viewModel.pwdSuccess {
                        Text("Contraseña cambiada exitosamente.")
                            .foregroundColor(.appSuccess)
                    }
                }
            }
            .navigationTitle("Cambiar contraseña")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        viewModel.pwdError   = ""
                        viewModel.pwdSuccess = false
                        viewModel.currentPwd = ""
                        viewModel.newPwd     = ""
                        viewModel.confirmPwd = ""
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") {
                        viewModel.changePassword()
                        if viewModel.pwdSuccess {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.currentPwd.isBlank || viewModel.newPwd.isBlank || viewModel.confirmPwd.isBlank)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// ─────────────────────────────────────────────
// MARK: - AcercaDeView  (P17)
// ─────────────────────────────────────────────

struct AcercaDeView: View {

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        Form {
            // App Icon + Name
            Section {
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color.brandPrimary.opacity(0.10))
                            .frame(width: 80, height: 80)
                        Image(systemName: "storefront.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.brandPrimary)
                    }
                    Text("TecStore Manager")
                        .font(.system(.title2).bold())
                    Text("Versión \(appVersion) (\(buildNumber))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            // Institución
            Section("Institución") {
                LabeledContent("Centro educativo", value: "TECSUP")
                LabeledContent("Curso", value: "Desarrollo de Apps Móviles")
                LabeledContent("Docente", value: "Juan León")
                LabeledContent("Año", value: "\(Calendar.current.component(.year, from: Date()))")
            }

            // Tecnología
            Section("Stack tecnológico") {
                LabeledContent("Lenguaje",    value: "Swift")
                LabeledContent("UI",          value: "UIKit + SwiftUI")
                LabeledContent("Base de datos", value: "Core Data (SQLite)")
                LabeledContent("Mapas",       value: "MapKit + CoreLocation")
                LabeledContent("Plataforma",  value: "iOS 17+")
                LabeledContent("Arquitectura", value: "MVC (UIKit) · MVVM (SwiftUI)")
            }

            // Funcionalidades
            Section("Funcionalidades") {
                FeatureRow(icon: "shippingbox.fill",   text: "Gestión de productos con categorías")
                FeatureRow(icon: "person.2.fill",      text: "Gestión de clientes con ubicación")
                FeatureRow(icon: "cart.fill",           text: "Registro de ventas con IGV")
                FeatureRow(icon: "chart.bar.fill",      text: "Reportes y métricas de la tienda")
                FeatureRow(icon: "magnifyingglass",     text: "Búsqueda unificada")
                FeatureRow(icon: "mappin.and.ellipse",  text: "Mapa interactivo con pin manual")
                FeatureRow(icon: "moon.fill",           text: "Modo oscuro")
            }
        }
        .navigationTitle("Acerca de")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    var body: some View {
        Label(text, systemImage: icon)
            .font(.subheadline)
            .foregroundColor(.primary)
    }
}
