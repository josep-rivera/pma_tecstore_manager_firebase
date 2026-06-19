import Foundation
import CoreData

// ─────────────────────────────────────────────
// MARK: - SeederService
// ─────────────────────────────────────────────

final class SeederService {

    static let shared = SeederService()
    private init() {}

    private let persistence = PersistenceController.shared
    private var context: NSManagedObjectContext { persistence.viewContext }

    private let seededKey = "seederCompleted_v6"

    func seedIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        clearAllEntities()
        seed()
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    private func clearAllEntities() {
        let entities = ["DetalleVenta", "Venta", "Ubicacion", "Cliente", "Producto", "Usuario"]
        for name in entities {
            let req = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            let del = NSBatchDeleteRequest(fetchRequest: req)
            _ = try? context.execute(del)
        }
        context.reset()
    }

    private func seed() {
        let usuarios  = seedUsuarios()
        let productos = seedProductos()
        let clientes  = seedClientes()
        seedVentas(usuarios: usuarios, productos: productos, clientes: clientes)
        persistence.save()
        print("SeederService: base de datos inicializada (v4).")
    }

    // ─────────────────────────────────────────
    // MARK: - Usuarios (3)
    // ─────────────────────────────────────────

    @discardableResult
    private func seedUsuarios() -> [Usuario] {
        let data: [(name: String, email: String, pwd: String)] = [
            ("Ana García López",       "ana.garcia@tecsup.edu.pe",     "123456"),
            ("Carlos Mendoza Ríos",    "carlos.mendoza@tecsup.edu.pe", "123456"),
            ("Sofía Torres Castillo",  "sofia.torres@tecsup.edu.pe",   "123456")
        ]
        return data.map { item in
            let u            = Usuario(context: context)
            u.idUsuario      = UUID()
            u.nombreCompleto = item.name
            u.correo         = item.email
            u.passwordHash   = PasswordHasher.hash(item.pwd)
            u.fechaRegistro  = daysAgo(Int.random(in: 60...90))
            return u
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Productos (16)
    //
    // `image` names must exist in Assets.xcassets.
    // Use nil for products without an asset.
    // ─────────────────────────────────────────

    @discardableResult
    private func seedProductos() -> [Producto] {
        let data: [(code: String, name: String, cat: String, price: Double, stock: Int32, active: Bool, image: String?)] = [
            // Electrónica
            ("ELEC-001", "Audifonos Bluetooth Pro",   "Electrónica", 89.90,  35, true,  "product_audifonos"),
            ("ELEC-002", "Cable USB-C 2m",             "Electrónica", 15.50,  25, true,  "product_cable_usbc"),
            ("ELEC-003", "Hub USB-C 7 en 1",           "Electrónica", 79.90,  18, true,  "product_hub_usbc"),
            ("ELEC-004", "Cargador Inalámbrico 15W",   "Electrónica", 45.00,   0, true,  "product_cargador"),
            // Tecnología
            ("TEC-001",  "Teclado Mecánico RGB",       "Tecnología",  149.90, 25, true,  "product_teclado"),
            ("TEC-002",  "Mouse Inalámbrico Silencioso","Tecnología",  55.00,  14, true,  "product_mouse"),
            ("TEC-003",  "Monitor 24\" Full HD",        "Tecnología",  699.00,  6, true,  "product_monitor"),
            ("TEC-004",  "Laptop Bag 15.6\" Impermeable","Tecnología", 65.00,  20, true,  "product_laptop_bag"),
            // Ropa
            ("ROPA-001", "Polo Algodón Premium M",     "Ropa",         35.00,  40, true,  "product_polo"),
            ("ROPA-002", "Polo Running Dry Fit L",      "Ropa",         55.00,  28, true,  "product_polo_dryfit"),
            // Deportes
            ("DEPO-001", "Mochila Deportiva 30L",      "Deportes",     75.00,  22, true,  "product_mochila"),
            ("DEPO-002", "Zapatillas Trail Running",   "Deportes",    220.00,  10, true,  "product_zapatillas"),
            // Hogar
            ("HOGAR-001","Organizador de Escritorio",  "Hogar",        22.50,   8, false, "product_organizador"),
            ("HOGAR-002","Silla Gamer Ergonómica",     "Hogar",       450.00,   4, true,  "product_silla_gamer"),
            // Alimentos
            ("ALIM-001", "Agua Mineral 600ml x24",     "Alimentos",    28.00,  70, true,  "product_agua"),
            // Limpieza
            ("LIMP-001", "Desinfectante Multiuso 1L",  "Limpieza",     18.50,  55, true,  "product_desinfectante"),
        ]

        return data.map { item in
            let p           = Producto(context: context)
            p.idProducto    = UUID()
            p.codigo        = item.code
            p.nombre        = item.name
            p.categoria     = item.cat
            p.precio        = NSDecimalNumber(value: item.price)
            p.stock         = item.stock
            p.estado        = item.active ? "Activo" : "Inactivo"
            p.fechaRegistro = daysAgo(Int.random(in: 15...75))
            p.fotoProducto  = item.image
            return p
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Clientes (13)
    //
    // lat/lon nil  → no Ubicacion at all (test: add location from scratch)
    // ref nil      → coordinates set but no address text (test: reverse geocode on drag)
    // ref non-nil  → full address + coords (test: forward geocode on type)
    // ─────────────────────────────────────────

    @discardableResult
    private func seedClientes() -> [Cliente] {
        struct ClienteSeed {
            let dni: String; let nom: String; let ape: String
            let tel: String?; let mail: String?
            let lat: Double?; let lon: Double?; let ref: String?
        }
        let data: [ClienteSeed] = [
            // Full address + coordinates (forward geocoding test)
            .init(dni: "72345678", nom: "Luis",      ape: "Ramírez Torres",
                  tel: "987654321", mail: "luis.ramirez@gmail.com",
                  lat: -12.11929,   lon: -77.03098,
                  ref: "Av. Larco 1150, Miraflores, Lima"),
            .init(dni: "69876543", nom: "José",      ape: "Flores Vega",
                  tel: nil,         mail: "jose.flores@outlook.com",
                  lat: -12.07748,   lon: -77.08290,
                  ref: "Av. La Marina 2595, San Miguel, Lima"),
            .init(dni: "75432198", nom: "Carmen",    ape: "Soto Alvarado",
                  tel: "965432109", mail: "carmen.s@hotmail.com",
                  lat: -12.13826,   lon: -77.00587,
                  ref: "Av. Caminos del Inca 460, Santiago de Surco, Lima"),
            .init(dni: "74123456", nom: "Valeria",   ape: "Huaman Ccopa",
                  tel: "943210987", mail: "valeria.h@gmail.com",
                  lat: -12.07831,   lon: -76.92717,
                  ref: "Av. La Molina 1634, La Molina, Lima"),
            .init(dni: "61987654", nom: "Andrés",    ape: "Paredes Salinas",
                  tel: "932109876", mail: "andres.p@yahoo.com",
                  lat: -12.14248,   lon: -77.02088,
                  ref: "Jr. Junín 282, Barranco, Lima"),
            .init(dni: "85321098", nom: "Miguel",    ape: "Quispe Condori",
                  tel: "910987654", mail: "miguel.q@gmail.com",
                  lat: -12.08531,   lon: -77.03524,
                  ref: "Av. Arequipa 2450, Lince, Lima"),
            .init(dni: "72901234", nom: "Fernando",  ape: "Castillo Aguirre",
                  tel: "899876543", mail: "fernando.c@gmail.com",
                  lat: -12.12283,   lon: -77.03217,
                  ref: "Av. José Larco 400, Miraflores, Lima"),
            .init(dni: "65432109", nom: "Diego",     ape: "Romero Navarro",
                  tel: "877654321", mail: "diego.r@outlook.com",
                  lat: -11.99306,   lon: -77.06197,
                  ref: "Av. Universitaria 1801, Los Olivos, Lima"),
            // Coordinates only — no address text (drag pin → reverse geocode)
            .init(dni: "81234567", nom: "María",     ape: "Quispe Huanca",
                  tel: "976543210", mail: nil,
                  lat: -12.10978,   lon: -77.04302,
                  ref: nil),
            .init(dni: "83210987", nom: "Roberto",   ape: "Chinchay Mamani",
                  tel: "954321098", mail: nil,
                  lat: -12.09718,   lon: -77.03458,
                  ref: nil),
            .init(dni: "78654321", nom: "Lucía",     ape: "Mendez Rojas",
                  tel: "921098765", mail: nil,
                  lat: -12.07852,   lon: -77.05192,
                  ref: nil),
            // No location at all (add location from scratch)
            .init(dni: "67890123", nom: "Patricia",  ape: "Vera Campos",
                  tel: nil,         mail: "patricia.v@hotmail.com",
                  lat: nil,         lon: nil,
                  ref: nil),
            .init(dni: "80765432", nom: "Ana Lucía", ape: "Pinto Herrera",
                  tel: "888765432", mail: nil,
                  lat: nil,         lon: nil,
                  ref: nil),
        ]

        return data.map { item in
            let c            = Cliente(context: context)
            c.idCliente      = UUID()
            c.dni            = item.dni
            c.nombres        = item.nom
            c.apellidos      = item.ape
            c.telefono       = item.tel
            c.correo         = item.mail
            c.estado         = "Activo"
            c.fechaRegistro  = daysAgo(Int.random(in: 5...45))

            c.direccion = item.ref   // shown in the detail view

            if let lat = item.lat, let lon = item.lon {
                let ub                 = Ubicacion(context: context)
                ub.idUbicacion         = UUID()
                ub.latitud             = NSDecimalNumber(value: lat)
                ub.longitud            = NSDecimalNumber(value: lon)
                ub.direccionReferencia = item.ref
                ub.fechaRegistro       = c.fechaRegistro
                ub.cliente             = c
            }

            return c
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Ventas (25)
    // ─────────────────────────────────────────

    private func seedVentas(usuarios: [Usuario], productos: [Producto], clientes: [Cliente]) {
        guard usuarios.count >= 2, clientes.count >= 5 else { return }

        let u0 = usuarios[0]
        let u1 = usuarios[1]
        let u2 = usuarios.count > 2 ? usuarios[2] : u1

        let sellable = productos.filter { $0.isActive && $0.stock > 0 }
        guard sellable.count >= 3 else { return }

        // (clientIdx, userIdx, daysAgo, productCount)
        let scenarios: [(Int, Int, Int, Int)] = [
            (0, 0,  1, 2), (1, 1,  1, 1), (2, 2,  2, 2),
            (3, 0,  3, 1), (4, 1,  3, 2), (5, 2,  4, 1),
            (6, 0,  5, 3), (7, 1,  5, 1), (8, 2,  6, 2),
            (0, 0,  7, 1), (1, 1,  8, 2), (2, 2,  9, 1),
            (9, 0, 10, 2), (10,1, 11, 1), (11,2, 12, 2),
            (3, 0, 13, 1), (4, 1, 14, 3), (5, 2, 15, 1),
            (6, 0, 17, 2), (7, 1, 18, 1), (12,2, 20, 2),
            (8, 0, 22, 1), (9, 1, 25, 2), (10,2, 28, 1),
            (0, 0, 30, 2),
        ]

        let users = [u0, u1, u2]

        for (ci, ui, days, pickCount) in scenarios {
            guard ci < clientes.count else { continue }
            let cliente = clientes[ci]
            let usuario = users[ui % users.count]

            let pool   = Array(sellable.shuffled().prefix(pickCount))
            var items: [(product: Producto, qty: Int32, price: NSDecimalNumber)] = []

            for product in pool {
                let maxQty = min(2, product.stock)
                guard maxQty >= 1 else { continue }
                let qty: Int32 = Int32.random(in: 1...maxQty)
                items.append((product, qty, product.precio ?? NSDecimalNumber.zero))
            }
            guard !items.isEmpty else { continue }

            let subtotal: Decimal = items.reduce(0) { $0 + ($1.price.decimalValue * Decimal($1.qty)) }
            let igv               = subtotal * Decimal(18) / Decimal(100)
            let total             = subtotal + igv

            let venta        = Venta(context: context)
            venta.idVenta    = UUID()
            venta.fechaVenta = daysAgo(days)
            venta.subtotal   = NSDecimalNumber(decimal: subtotal)
            venta.igv        = NSDecimalNumber(decimal: igv)
            venta.total      = NSDecimalNumber(decimal: total)
            venta.estado     = "Completada"
            venta.cliente    = cliente
            venta.usuario    = usuario

            for item in items {
                let d            = DetalleVenta(context: context)
                d.idDetalleVenta = UUID()
                d.cantidad       = item.qty
                d.precioUnitario = item.price
                d.subtotalLinea  = NSDecimalNumber(decimal: item.price.decimalValue * Decimal(item.qty))
                d.venta          = venta
                d.producto       = item.product
                item.product.stock -= item.qty
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Helpers
    // ─────────────────────────────────────────

    private func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: Date()) ?? Date()
    }
}
