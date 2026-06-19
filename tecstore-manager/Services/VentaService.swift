import Foundation
import CoreData

// ─────────────────────────────────────────────
// MARK: - VentaItem
// ─────────────────────────────────────────────

/// Represents one line in a sale: a product + quantity + price snapshot.
/// Used by `RegistroVentaViewModel` to build the cart before confirming.
struct VentaItem: Identifiable {
    let id              = UUID()            // SwiftUI list identity
    let producto:         Producto
    var cantidad:         Int
    var precioUnitario:   Decimal           // snapshot at time of sale

    /// cantidad × precioUnitario
    var subtotalLinea: Decimal { precioUnitario * Decimal(cantidad) }

    /// Display string for the subtotal.
    var subtotalDisplay: String { subtotalLinea.asCurrency }

    var productName: String { producto.productName }
    var quantityInt: Int    { cantidad }
}

// ─────────────────────────────────────────────
// MARK: - VentaService
// ─────────────────────────────────────────────

final class VentaService {

    // MARK: Singleton
    static let shared = VentaService()
    private init() {}

    private let persistence = PersistenceController.shared
    private var context: NSManagedObjectContext { persistence.viewContext }

    // ─────────────────────────────────────────
    // MARK: - Fetch
    // ─────────────────────────────────────────

    /// All sales, newest first.
    func fetchAll() -> [Venta] {
        persistence.fetch(Venta.all())
    }

    /// Single sale by primary key, or nil.
    func fetch(byID id: UUID) -> Venta? {
        persistence.fetch(Venta.byID(id)).first
    }

    /// Sales whose fechaVenta falls inside the given range (inclusive).
    func fetch(from start: Date, to end: Date) -> [Venta] {
        // Extend `end` to include the full last day
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: end) ?? end
        return persistence.fetch(Venta.byDateRange(from: start, to: endOfDay))
    }

    /// The single most recent sale, or nil if no sales exist yet.
    func fetchMostRecent() -> Venta? {
        persistence.fetch(Venta.mostRecent()).first
    }

    // ─────────────────────────────────────────
    // MARK: - Search
    // ─────────────────────────────────────────

    /// Search by client's nombre, apellidos, or DNI.
    /// Returns all sales when `text` is empty.
    func search(text: String) -> [Venta] {
        let trimmed = text.trimmed
        guard trimmed.isNotBlank else { return fetchAll() }
        return persistence.fetch(Venta.search(text: trimmed))
    }

    // ─────────────────────────────────────────
    // MARK: - Register
    // ─────────────────────────────────────────

    /// Create a new sale, record its line items, and deduct stock.
    ///
    /// Business rules enforced:
    /// - Cart must contain at least one item.
    /// - Each item's `cantidad` must not exceed the product's current stock.
    /// - `subtotalLinea` = cantidad × precioUnitario (snapshot).
    /// - `subtotal` = sum of all subtotalLinea.
    /// - `igv`     = subtotal × 0.18.
    /// - `total`   = subtotal + igv.
    ///
    /// - Throws: `ServiceError.emptyCart` or `ServiceError.insufficientStock`.
    /// - Returns: The newly persisted `Venta`.
    @discardableResult
    func register(
        cliente:  Cliente,
        usuario:  Usuario,
        items:    [VentaItem]
    ) throws -> Venta {

        // 1. Validate cart is not empty
        guard !items.isEmpty else { throw ServiceError.emptyCart }

        // 2. Validate stock for every item (check all before writing anything)
        for item in items {
            let available = item.producto.stockInt
            guard available >= item.cantidad else {
                throw ServiceError.insufficientStock(
                    productName: item.producto.productName,
                    available: available
                )
            }
        }

        // 3. Calculate totals (single source of truth, rounded to cents)
        let (subtotal, igv, total) = calculateTotals(for: items)

        // 4. Create the Venta header
        let venta            = Venta(context: context)
        venta.idVenta        = UUID()
        venta.fechaVenta     = Date()
        venta.subtotal       = NSDecimalNumber(decimal: subtotal)
        venta.igv            = NSDecimalNumber(decimal: igv)
        venta.total          = NSDecimalNumber(decimal: total)
        venta.estado         = "Completada"
        venta.cliente        = cliente
        venta.usuario        = usuario

        // 5. Create DetalleVenta records and deduct stock
        for item in items {
            let detalle                = DetalleVenta(context: context)
            detalle.idDetalleVenta     = UUID()
            detalle.cantidad           = Int32(item.cantidad)
            detalle.precioUnitario     = NSDecimalNumber(decimal: item.precioUnitario)
            detalle.subtotalLinea      = NSDecimalNumber(decimal: item.subtotalLinea)
            detalle.venta              = venta
            detalle.producto           = item.producto

            // Deduct stock — product is already in the viewContext
            item.producto.stock       -= Int32(item.cantidad)
        }

        // 6. Single save for the entire transaction
        persistence.save()
        NotificationCenter.default.post(name: .salesDataChanged, object: nil)
        return venta
    }

    // ─────────────────────────────────────────
    // MARK: - Cart Helpers  (convenience for ViewModel)
    // ─────────────────────────────────────────

    /// Build a `VentaItem` from a product using its current price as the snapshot.
    func buildItem(product: Producto, cantidad: Int) -> VentaItem {
        VentaItem(producto: product, cantidad: cantidad, precioUnitario: product.priceDecimal)
    }

    /// IGV (sales tax) rate applied to every sale.
    static let igvRate = Decimal(18) / Decimal(100)   // 18 %

    /// Recalculate cart totals from a list of `VentaItem`.
    /// All amounts are rounded to cents so stored and displayed values match.
    func calculateTotals(for items: [VentaItem]) -> (subtotal: Decimal, igv: Decimal, total: Decimal) {
        let subtotal = items.reduce(Decimal(0)) { $0 + $1.subtotalLinea }.roundedToCents
        let igv      = (subtotal * Self.igvRate).roundedToCents
        let total    = subtotal + igv
        return (subtotal, igv, total)
    }
}
