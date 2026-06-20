import SwiftUI
import Combine

// ─────────────────────────────────────────────
// MARK: - InicioViewModel
// ─────────────────────────────────────────────

@MainActor
final class InicioViewModel: ObservableObject {

    @Published var todaySalesCount:  Int     = 0
    @Published var todaySalesTotal:  Double  = 0
    @Published var outOfStockCount:  Int     = 0
    @Published var totalClientes:    Int     = 0
    @Published var userName:         String? = nil

    func loadMetrics() {
        Task {
            do {
                async let today         = ReporteService.shared.todayMetrics()
                async let outOfStock    = ReporteService.shared.countOutOfStock()
                async let clientesCount = ReporteService.shared.countClientes()
                async let usuario       = AuthService.shared.currentUsuario()

                let t = try await today
                todaySalesCount = t.count
                todaySalesTotal = t.total
                outOfStockCount = try await outOfStock
                totalClientes   = try await clientesCount
                userName        = try await usuario?.fullName
            } catch {
                // metrics stay at zero on error
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - InicioView
// ─────────────────────────────────────────────

struct InicioView: View {

    @StateObject private var viewModel = InicioViewModel()

    var onBusquedas:  (() -> Void)? = nil
    var onReportes:   (() -> Void)? = nil
    var onStockBajo:  (() -> Void)? = nil
    var onNuevaVenta: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: CGFloat(AppLayout.paddingLarge)) {

                welcomeHeader

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: CGFloat(AppLayout.padding)
                ) {
                    MetricCard(icon: "cart.fill",   color: .brandPrimary,
                               value: "\(viewModel.todaySalesCount)", label: "Ventas hoy")
                    MetricCard(icon: "banknote.fill", color: Color.appSuccess,
                               value: viewModel.todaySalesTotal.asCurrency, label: "Ingresos hoy")
                    MetricCard(icon: "exclamationmark.triangle.fill", color: Color.appWarning,
                               value: "\(viewModel.outOfStockCount)", label: "Sin stock")
                    MetricCard(icon: "person.2.fill", color: Color(UIColor.systemIndigo),
                               value: "\(viewModel.totalClientes)", label: "Clientes")
                }
                .padding(.horizontal, CGFloat(AppLayout.padding))

                shortcutsSection
            }
            .padding(.vertical, CGFloat(AppLayout.padding))
        }
        .background(Color(UIColor.appGrouped))
        .navigationTitle("Inicio")
        .onAppear { viewModel.loadMetrics() }
        .onReceive(NotificationCenter.default.publisher(for: .salesDataChanged)) { _ in
            viewModel.loadMetrics()
        }
    }

    // ── Welcome ──
    private var welcomeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Bienvenido")
                    .font(.system(.title2).bold())
                if let name = viewModel.userName {
                    Text(name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Image(systemName: "storefront.fill")
                .font(.system(.title))
                .foregroundColor(.brandPrimary)
        }
        .padding(CGFloat(AppLayout.paddingLarge))
        .background(Color(UIColor.systemBackground))
        .cornerRadius(CGFloat(AppLayout.cornerRadius))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        .padding(.horizontal, CGFloat(AppLayout.padding))
    }

    // ── Shortcuts ──
    private var shortcutsSection: some View {
        VStack(spacing: CGFloat(AppLayout.paddingSmall)) {
            Text("Accesos rápidos")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, CGFloat(AppLayout.padding))

            Button { onBusquedas?() } label: {
                ShortcutCard(icon: "magnifyingglass", title: "Búsquedas",
                             subtitle: "Buscar en productos, clientes y ventas",
                             color: .brandPrimary)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, CGFloat(AppLayout.padding))

            Button { onReportes?() } label: {
                ShortcutCard(icon: "chart.bar.fill", title: "Reportes",
                             subtitle: "Métricas y tendencias de la tienda",
                             color: Color.appSuccess)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, CGFloat(AppLayout.padding))

            Button { onNuevaVenta?() } label: {
                ShortcutCard(icon: "cart.badge.plus", title: "Nueva venta",
                             subtitle: "Registrar una venta rápidamente",
                             color: Color(UIColor.systemOrange))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, CGFloat(AppLayout.padding))

            Button { onStockBajo?() } label: {
                ShortcutCard(icon: "exclamationmark.triangle.fill", title: "Stock bajo",
                             subtitle: "Productos con 5 unidades o menos",
                             color: Color.appWarning)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, CGFloat(AppLayout.padding))
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - StockBajoView
// ─────────────────────────────────────────────

struct StockBajoView: View {

    @State private var productos: [FBProducto] = []

    var body: some View {
        Group {
            if productos.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.appSuccess)
                    Text("Todos los productos tienen stock suficiente")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(productos) { p in
                    HStack(spacing: 12) {
                        Group {
                            if let path = p.productImagePath,
                               let uiImg = UIImage(named: path) ?? UIImage.fromDocuments(named: path) {
                                Image(uiImage: uiImg)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: p.categoryEnum.icon)
                                    .font(.system(.title3))
                                    .foregroundColor(Color(UIColor.colorForCategory(p.categoryValue)))
                            }
                        }
                        .frame(width: 36, height: 36)
                        .background(Color(UIColor.colorForCategory(p.categoryValue)).opacity(0.12))
                        .cornerRadius(8)
                        .clipped()

                        VStack(alignment: .leading, spacing: 3) {
                            Text(p.productName).font(.subheadline.weight(.medium))
                            Text(p.productCode).font(.caption).foregroundColor(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 3) {
                            Text("\(p.stockInt) ud.")
                                .font(.subheadline.bold())
                                .foregroundColor(Color(p.stockInt.stockUIColor))
                            Text(p.stockInt.stockLabel)
                                .font(.caption2)
                                .foregroundColor(Color(p.stockInt.stockUIColor))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Stock bajo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            Task {
                do {
                    let all = try await ProductoService.shared.fetchAll()
                    productos = all
                        .filter { $0.isActive && $0.stockInt <= 5 }
                        .sorted { $0.stockInt < $1.stockInt }
                } catch {
                    // leave list empty on error
                }
            }
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Reusable Card Components
// ─────────────────────────────────────────────

struct MetricCard: View {
    let icon:   String
    let color:  Color
    let value:  String
    let label:  String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(.title3))
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.system(.title2).bold())
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(CGFloat(AppLayout.padding))
        .background(Color(UIColor.systemBackground))
        .cornerRadius(CGFloat(AppLayout.cornerRadius))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}

struct ShortcutCard: View {
    let icon:     String
    let title:    String
    let subtitle: String
    let color:    Color

    var body: some View {
        HStack(spacing: CGFloat(AppLayout.padding)) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .font(.system(.title3))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color(UIColor.appTextTertiary))
        }
        .padding(CGFloat(AppLayout.padding))
        .background(Color(UIColor.systemBackground))
        .cornerRadius(CGFloat(AppLayout.cornerRadius))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}
