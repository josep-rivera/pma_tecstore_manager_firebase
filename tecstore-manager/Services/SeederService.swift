import Foundation
import FirebaseAuth
import FirebaseFirestore

// ─────────────────────────────────────────────
// MARK: - SeederService
// ─────────────────────────────────────────────

final class SeederService {

    static let shared = SeederService()
    private init() {}

    private let db = Firestore.firestore()
    private let seededKey = "seederCompleted_v8"

    // ─────────────────────────────────────────
    // MARK: - Public Entry Point
    // ─────────────────────────────────────────

    /// Seeds initial data if it has never been seeded on this device.
    /// Safe to call from SceneDelegate in a Task — async, throws suppressed at call site.
    func seedIfNeeded() async throws {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        try await seed()
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    /// Full wipe-and-seed: deletes all documents then re-inserts fixture data.
    /// Order: usuarios → productos → clientes → ventas.
    func seed() async throws {
        try await clearAllCollections()

        let usuarios  = try await seedUsuarios()
        let productos = try await seedProductos()
        let clientes  = try await seedClientes()
        try await seedVentas(usuarios: usuarios, productos: productos, clientes: clientes)

        print("SeederService: Firestore initialized (v6).")
    }

    // ─────────────────────────────────────────
    // MARK: - Wipe
    // ─────────────────────────────────────────

    /// Deletes all documents in all 4 Firestore collections.
    /// Auth users are NOT deleted (avoids emailAlreadyInUse on re-seed;
    /// signIn fallback handles existing Auth accounts below).
    private func clearAllCollections() async throws {
        let collections = [
            Collections.detallesVenta,
            Collections.ventas,
            Collections.clientes,
            Collections.productos,
            Collections.usuarios
        ]
        for name in collections {
            let snap = try await db.collection(name).getDocuments()
            for doc in snap.documents {
                try await doc.reference.delete()
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Usuarios (3)
    // ─────────────────────────────────────────

    private func seedUsuarios() async throws -> [FBUsuario] {
        let data: [(name: String, email: String, pwd: String)] = [
            ("Ana García López",      "ana.garcia@tecsup.edu.pe",     "123456"),
            ("Carlos Mendoza Ríos",   "carlos.mendoza@tecsup.edu.pe", "123456"),
            ("Sofía Torres Castillo", "sofia.torres@tecsup.edu.pe",   "123456")
        ]

        var usuarios: [FBUsuario] = []
        for item in data {
            let uid = try await getOrCreateAuthUser(email: item.email, password: item.pwd)
            let usuario = FBUsuario(
                id:             uid,
                nombreCompleto: item.name,
                correo:         item.email,
                fotoPerfil:     nil,
                fechaRegistro:  daysAgo(Int.random(in: 60...90))
            )
            try await FirestoreService.set(Collections.usuarios, id: uid, usuario)
            usuarios.append(usuario)
        }
        return usuarios
    }

    /// Creates the Firebase Auth user, or signs in if the email already exists.
    /// Returns the uid in both cases.
    private func getOrCreateAuthUser(email: String, password: String) async throws -> String {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            return result.user.uid
        } catch {
            // Fall back to sign-in when the account already exists.
            // AuthErrorCode.emailAlreadyInUse raw value = 17007.
            let nsError = error as NSError
            guard nsError.domain == AuthErrorDomain,
                  nsError.code == AuthErrorCode.emailAlreadyInUse.rawValue else {
                throw error
            }
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return result.user.uid
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Productos (16)
    // ─────────────────────────────────────────

    private func seedProductos() async throws -> [FBProducto] {
        typealias PData = (code: String, name: String, cat: String, price: Double, stock: Int, active: Bool, image: String?)
        let data: [PData] = [
            // Electrónica
            ("ELEC-001", "Audifonos Bluetooth Pro",    "Electrónica", 89.90,  35, true,  "product_audifonos"),
            ("ELEC-002", "Cable USB-C 2m",              "Electrónica", 15.50,  25, true,  "product_cable_usbc"),
            ("ELEC-003", "Hub USB-C 7 en 1",            "Electrónica", 79.90,  18, true,  "product_hub_usbc"),
            ("ELEC-004", "Cargador Inalámbrico 15W",    "Electrónica", 45.00,   0, true,  "product_cargador"),
            // Tecnología
            ("TEC-001",  "Teclado Mecánico RGB",        "Tecnología",  149.90, 25, true,  "product_teclado"),
            ("TEC-002",  "Mouse Inalámbrico Silencioso", "Tecnología",  55.00,  14, true,  "product_mouse"),
            ("TEC-003",  "Monitor 24\" Full HD",         "Tecnología",  699.00,  6, true,  "product_monitor"),
            ("TEC-004",  "Laptop Bag 15.6\" Impermeable","Tecnología",  65.00,  20, true,  "product_laptop_bag"),
            // Ropa
            ("ROPA-001", "Polo Algodón Premium M",      "Ropa",         35.00,  40, true,  "product_polo"),
            ("ROPA-002", "Polo Running Dry Fit L",       "Ropa",         55.00,  28, true,  "product_polo_dryfit"),
            // Deportes
            ("DEPO-001", "Mochila Deportiva 30L",       "Deportes",     75.00,  22, true,  "product_mochila"),
            ("DEPO-002", "Zapatillas Trail Running",    "Deportes",    220.00,  10, true,  "product_zapatillas"),
            // Hogar
            ("HOGAR-001","Organizador de Escritorio",   "Hogar",        22.50,   8, false, "product_organizador"),
            ("HOGAR-002","Silla Gamer Ergonómica",      "Hogar",       450.00,   4, true,  "product_silla_gamer"),
            // Alimentos
            ("ALIM-001", "Agua Mineral 600ml x24",      "Alimentos",    28.00,  70, true,  "product_agua"),
            // Limpieza
            ("LIMP-001", "Desinfectante Multiuso 1L",   "Limpieza",     18.50,  55, true,  "product_desinfectante"),
        ]

        var productos: [FBProducto] = []
        for item in data {
            let ref = db.collection(Collections.productos).document()
            let producto = FBProducto(
                id:            ref.documentID,
                codigo:        item.code,
                nombre:        item.name,
                categoria:     item.cat,
                precio:        item.price,
                stock:         item.stock,
                fotoProducto:  item.image,
                estado:        item.active ? "Activo" : "Inactivo",
                fechaRegistro: daysAgo(Int.random(in: 15...75))
            )
            try ref.setData(from: producto)
            productos.append(producto)
        }
        return productos
    }

    // ─────────────────────────────────────────
    // MARK: - Clientes (13)
    // ─────────────────────────────────────────

    private func seedClientes() async throws -> [FBCliente] {
        struct ClienteSeed {
            let dni: String; let nom: String; let ape: String
            let tel: String?; let mail: String?; let dir: String?
            let lat: Double?; let lon: Double?; let ref: String?
        }
        let data: [ClienteSeed] = [
            .init(dni: "72345678", nom: "Luis",      ape: "Ramírez Torres",
                  tel: "987654321", mail: "luis.ramirez@gmail.com",
                  dir: "Av. Larco 1150, Miraflores, Lima",
                  lat: -12.11929,   lon: -77.03098,
                  ref: "Av. Larco 1150, Miraflores, Lima"),
            .init(dni: "69876543", nom: "José",      ape: "Flores Vega",
                  tel: nil,         mail: "jose.flores@outlook.com",
                  dir: "Av. La Marina 2595, San Miguel, Lima",
                  lat: -12.07748,   lon: -77.08290,
                  ref: "Av. La Marina 2595, San Miguel, Lima"),
            .init(dni: "75432198", nom: "Carmen",    ape: "Soto Alvarado",
                  tel: "965432109", mail: "carmen.s@hotmail.com",
                  dir: "Av. Caminos del Inca 460, Santiago de Surco, Lima",
                  lat: -12.13826,   lon: -77.00587,
                  ref: "Av. Caminos del Inca 460, Santiago de Surco, Lima"),
            .init(dni: "74123456", nom: "Valeria",   ape: "Huaman Ccopa",
                  tel: "943210987", mail: "valeria.h@gmail.com",
                  dir: "Av. La Molina 1634, La Molina, Lima",
                  lat: -12.07831,   lon: -76.92717,
                  ref: "Av. La Molina 1634, La Molina, Lima"),
            .init(dni: "61987654", nom: "Andrés",    ape: "Paredes Salinas",
                  tel: "932109876", mail: "andres.p@yahoo.com",
                  dir: "Jr. Junín 282, Barranco, Lima",
                  lat: -12.14248,   lon: -77.02088,
                  ref: "Jr. Junín 282, Barranco, Lima"),
            .init(dni: "85321098", nom: "Miguel",    ape: "Quispe Condori",
                  tel: "910987654", mail: "miguel.q@gmail.com",
                  dir: "Av. Arequipa 2450, Lince, Lima",
                  lat: -12.08531,   lon: -77.03524,
                  ref: "Av. Arequipa 2450, Lince, Lima"),
            .init(dni: "72901234", nom: "Fernando",  ape: "Castillo Aguirre",
                  tel: "899876543", mail: "fernando.c@gmail.com",
                  dir: "Av. José Larco 400, Miraflores, Lima",
                  lat: -12.12283,   lon: -77.03217,
                  ref: "Av. José Larco 400, Miraflores, Lima"),
            .init(dni: "65432109", nom: "Diego",     ape: "Romero Navarro",
                  tel: "877654321", mail: "diego.r@outlook.com",
                  dir: "Av. Universitaria 1801, Los Olivos, Lima",
                  lat: -11.99306,   lon: -77.06197,
                  ref: "Av. Universitaria 1801, Los Olivos, Lima"),
            .init(dni: "81234567", nom: "María",     ape: "Quispe Huanca",
                  tel: "976543210", mail: nil,         dir: nil,
                  lat: -12.10978,   lon: -77.04302,    ref: nil),
            .init(dni: "83210987", nom: "Roberto",   ape: "Chinchay Mamani",
                  tel: "954321098", mail: nil,         dir: nil,
                  lat: -12.09718,   lon: -77.03458,    ref: nil),
            .init(dni: "78654321", nom: "Lucía",     ape: "Mendez Rojas",
                  tel: "921098765", mail: nil,         dir: nil,
                  lat: -12.07852,   lon: -77.05192,    ref: nil),
            .init(dni: "67890123", nom: "Patricia",  ape: "Vera Campos",
                  tel: nil,         mail: "patricia.v@hotmail.com",
                  dir: nil,         lat: nil,  lon: nil,  ref: nil),
            .init(dni: "80765432", nom: "Ana Lucía", ape: "Pinto Herrera",
                  tel: "888765432", mail: nil,
                  dir: nil,         lat: nil,  lon: nil,  ref: nil),
        ]

        var clientes: [FBCliente] = []
        for item in data {
            let ref = db.collection(Collections.clientes).document()
            var ubicacion: FBUbicacion? = nil
            if let lat = item.lat, let lon = item.lon {
                ubicacion = FBUbicacion(
                    latitud:             lat,
                    longitud:            lon,
                    direccionReferencia: item.ref,
                    fechaRegistro:       daysAgo(Int.random(in: 5...45))
                )
            }
            let cliente = FBCliente(
                id:            ref.documentID,
                dni:           item.dni,
                nombres:       item.nom,
                apellidos:     item.ape,
                telefono:      item.tel,
                correo:        item.mail,
                direccion:     item.dir,
                estado:        "Activo",
                fechaRegistro: daysAgo(Int.random(in: 5...45)),
                ubicacion:     ubicacion
            )
            try ref.setData(from: cliente)
            clientes.append(cliente)
        }
        return clientes
    }

    // ─────────────────────────────────────────
    // MARK: - Ventas (25)
    // ─────────────────────────────────────────

    private func seedVentas(
        usuarios:  [FBUsuario],
        productos: [FBProducto],
        clientes:  [FBCliente]
    ) async throws {
        guard usuarios.count >= 2, clientes.count >= 5 else { return }

        let u0 = usuarios[0]
        let u1 = usuarios[1]
        let u2 = usuarios.count > 2 ? usuarios[2] : u1
        let users = [u0, u1, u2]

        // Mutable stock tracking (in-memory, seeder only)
        var stockMap: [String: Int] = [:]
        for p in productos { if let id = p.id { stockMap[id] = p.stock } }

        let sellable = productos.filter { $0.isActive && ($0.stock) > 0 }
        guard sellable.count >= 3 else { return }

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

        let batch = FirestoreService.batch()

        for (ci, ui, days, pickCount) in scenarios {
            guard ci < clientes.count else { continue }
            let cliente = clientes[ci]
            let usuario = users[ui % users.count]

            let ventaRef = db.collection(Collections.ventas).document()
            let pool = Array(sellable.shuffled().prefix(pickCount))
            var detalles: [FBDetalleVenta] = []
            var subtotal: Double = 0

            for producto in pool {
                guard let productID = producto.id else { continue }
                let availableStock = stockMap[productID] ?? 0
                let maxQty = min(2, availableStock)
                guard maxQty >= 1 else { continue }
                let qty = Int.random(in: 1...maxQty)
                let lineTotal = producto.precio * Double(qty)
                subtotal += lineTotal

                detalles.append(FBDetalleVenta(
                    id:                UUID().uuidString,
                    ventaId:           ventaRef.documentID,
                    productoId:        productID,
                    productoNombre:    producto.nombre,
                    productoCodigo:    producto.codigo,
                    productoCategoria: producto.categoria,
                    cantidad:          qty,
                    precioUnitario:    producto.precio,
                    subtotalLinea:     lineTotal
                ))
                stockMap[productID] = availableStock - qty
            }

            guard !detalles.isEmpty else { continue }

            let igv   = (subtotal * 0.18 * 100).rounded() / 100
            let total = subtotal + igv

            let venta = FBVenta(
                id:             ventaRef.documentID,
                fechaVenta:     daysAgo(days),
                subtotal:       (subtotal * 100).rounded() / 100,
                igv:            igv,
                total:          total,
                estado:         "Completada",
                clienteId:      cliente.id,
                clienteNombre:  cliente.fullName,
                clienteDNI:     cliente.dni,
                usuarioId:      usuario.id,
                vendedorNombre: usuario.nombreCompleto,
                detalles:       detalles
            )
            try batch.setData(from: venta, forDocument: ventaRef)

            for detalle in detalles {
                let ref = db.collection(Collections.detallesVenta).document(detalle.id)
                try batch.setData(from: detalle, forDocument: ref)
            }
        }

        // Update final stock values for all products that were decremented
        for (productID, newStock) in stockMap {
            let ref = db.collection(Collections.productos).document(productID)
            batch.updateData(["stock": newStock], forDocument: ref)
        }

        try await batch.commit()
    }

    // ─────────────────────────────────────────
    // MARK: - Helpers
    // ─────────────────────────────────────────

    private func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: Date()) ?? Date()
    }
}
