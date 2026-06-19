import UIKit
import SwiftUI
import Combine

// MARK: - InicioViewController

final class InicioViewController: UIViewController {
    private var hosting: UIHostingController<InicioView>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Inicio"
        navigationItem.largeTitleDisplayMode = .always

        hosting = UIHostingController(rootView: InicioView(
            onBusquedas:  { [weak self] in self?.performSegue(withIdentifier: "showBusquedas", sender: nil) },
            onReportes:   { [weak self] in self?.performSegue(withIdentifier: "showReportes", sender: nil) },
            onStockBajo:  { [weak self] in self?.performSegue(withIdentifier: "showStockBajo", sender: nil) },
            onNuevaVenta: { [weak self] in self?.performSegue(withIdentifier: "showNuevaVentaModal", sender: nil) }
        ))
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
    }
}

// MARK: - ListaVentasViewController

final class ListaVentasViewController: UIViewController {

    private let ventasVM   = ListaVentasViewModel()
    private var hosting:   UIHostingController<ListaVentasView>!
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Ventas"
        navigationItem.largeTitleDisplayMode = .always

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain, target: self, action: #selector(addSale))
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            style: .plain, target: self, action: #selector(showFilter))

        hosting = UIHostingController(rootView: ListaVentasView(
            viewModel: ventasVM,
            onSelectVenta: { [weak self] venta in self?.pushDetalle(venta) },
            onAddSale:     { [weak self] in self?.addSale() }
        ))
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)

        ventasVM.$isDateFiltering
            .receive(on: RunLoop.main)
            .sink { [weak self] filtering in
                let icon = filtering ? "line.3.horizontal.decrease.circle.fill"
                                     : "line.3.horizontal.decrease.circle"
                self?.navigationItem.leftBarButtonItem?.image = UIImage(systemName: icon)
                self?.navigationItem.leftBarButtonItem?.tintColor = filtering ? .brandPrimary : nil
            }
            .store(in: &cancellables)
    }

    @objc private func addSale() {
        performSegue(withIdentifier: "showRegistroVenta", sender: nil)
    }

    @objc private func showFilter() {
        ventasVM.showDateFilter = true
    }

    private func pushDetalle(_ venta: Venta) {
        performSegue(withIdentifier: "showDetalleVenta", sender: venta)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetalleVenta",
           let dest = segue.destination as? DetalleVentaViewController,
           let venta = sender as? Venta {
            dest.venta = venta
        }
    }
}

// MARK: - PerfilViewController

final class PerfilViewController: UIViewController {
    private var hosting: UIHostingController<PerfilView>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Perfil"
        navigationItem.largeTitleDisplayMode = .always

        hosting = UIHostingController(rootView: PerfilView())
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
    }
}

// MARK: - BienvenidaViewController
// BienvenidaView requires onLogin and onRegister callbacks.
// When loaded from the storyboard, navigation is handled by SceneDelegate.

final class BienvenidaViewController: UIViewController {
    private var hosting: UIHostingController<BienvenidaView>!

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)

        let sb = UIStoryboard(name: "Main", bundle: nil)
        let swiftUIView = BienvenidaView(
            onLogin: { [weak self] in
                let loginVC = sb.instantiateViewController(withIdentifier: "LoginViewController")
                self?.navigationController?.pushViewController(loginVC, animated: true)
            },
            onRegister: { [weak self] in
                let registroVC = sb.instantiateViewController(withIdentifier: "RegistroViewController")
                self?.navigationController?.pushViewController(registroVC, animated: true)
            }
        )

        hosting = UIHostingController(rootView: swiftUIView)
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
    }
}

// MARK: - RegistroVentaViewController
// RegistroVentaView requires an onSave callback.
// When used standalone (not modal), dismissing is handled by the navigation stack.

final class RegistroVentaViewController: UIViewController {
    private var hosting: UIHostingController<RegistroVentaView>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Nueva venta"
        navigationItem.largeTitleDisplayMode = .never

        let swiftUIView = RegistroVentaView(onSave: { [weak self] in
            if self?.presentingViewController != nil {
                self?.dismiss(animated: true)
            } else {
                self?.navigationController?.popViewController(animated: true)
            }
        })

        hosting = UIHostingController(rootView: swiftUIView)
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
    }
}

// MARK: - DetalleVentaViewController
// DetalleVentaView requires a Venta object.
// Inject via the venta property before or after instantiation.

final class DetalleVentaViewController: UIViewController {
    private var hosting: UIHostingController<AnyView>!

    var venta: Venta? {
        didSet {
            if let venta {
                hosting?.rootView = AnyView(DetalleVentaView(venta: venta))
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Detalle de venta"
        navigationItem.largeTitleDisplayMode = .never

        let content: AnyView = venta.map { AnyView(DetalleVentaView(venta: $0)) } ?? AnyView(EmptyView())
        hosting = UIHostingController(rootView: content)
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
    }
}

// MARK: - BusquedasViewController

final class BusquedasViewController: UIViewController {
    private var hosting: UIHostingController<BusquedasView>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Búsquedas"
        navigationItem.largeTitleDisplayMode = .always

        hosting = UIHostingController(rootView: BusquedasView())
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
    }
}

// MARK: - ReportesViewController

final class ReportesViewController: UIViewController {
    private var hosting: UIHostingController<ReportesView>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Reportes"
        navigationItem.largeTitleDisplayMode = .always

        hosting = UIHostingController(rootView: ReportesView())
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
    }
}

// MARK: - StockBajoViewController

final class StockBajoViewController: UIViewController {
    private var hosting: UIHostingController<StockBajoView>!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Stock bajo"
        navigationItem.largeTitleDisplayMode = .never

        hosting = UIHostingController(rootView: StockBajoView())
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)
    }
}
