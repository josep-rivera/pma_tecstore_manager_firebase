import UIKit
import SwiftUI

// MARK: - InicioHostingController
// InicioView owns its NavigationStack — hide UIKit nav bar to avoid double title.

final class InicioHostingController: UIHostingController<InicioView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: InicioView())
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

// MARK: - VentasHostingController
// ListaVentasView owns its NavigationStack — hide UIKit nav bar.

final class VentasHostingController: UIHostingController<ListaVentasView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: ListaVentasView())
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

// MARK: - PerfilHostingController
// PerfilView owns its NavigationStack — hide UIKit nav bar.

final class PerfilHostingController: UIHostingController<PerfilView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: PerfilView())
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

// MARK: - BusquedasHostingController

final class BusquedasHostingController: UIHostingController<BusquedasView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: BusquedasView())
    }
}

// MARK: - ReportesHostingController

final class ReportesHostingController: UIHostingController<ReportesView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: ReportesView())
    }
}

// MARK: - BienvenidaHostingController
// BienvenidaView requires onLogin and onRegister callbacks.
// When loaded from the storyboard, navigation is handled by SceneDelegate.

final class BienvenidaHostingController: UIHostingController<BienvenidaView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: BienvenidaView(onLogin: {}, onRegister: {}))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        let sb = UIStoryboard(name: "Main", bundle: nil)
        rootView = BienvenidaView(
            onLogin: { [weak self] in
                let loginVC = sb.instantiateViewController(withIdentifier: "LoginViewController")
                self?.navigationController?.pushViewController(loginVC, animated: true)
            },
            onRegister: { [weak self] in
                let registroVC = sb.instantiateViewController(withIdentifier: "RegistroViewController")
                self?.navigationController?.pushViewController(registroVC, animated: true)
            }
        )
    }
}

// MARK: - RegistroVentaHostingController
// RegistroVentaView requires an onSave callback.
// When used standalone (not modal), dismissing is handled by the navigation stack.

final class RegistroVentaHostingController: UIHostingController<RegistroVentaView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: RegistroVentaView(onSave: {}))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        rootView = RegistroVentaView(onSave: { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        })
    }
}

// MARK: - DetalleVentaHostingController
// DetalleVentaView requires a Venta object.
// This controller is intended to be used via programmatic push with a Venta injected
// after instantiation. The placeholder guard ensures a safe fallback.

final class DetalleVentaHostingController: UIHostingController<AnyView> {

    var venta: Venta? {
        didSet {
            if let venta {
                rootView = AnyView(DetalleVentaView(venta: venta))
            }
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: AnyView(EmptyView()))
    }
}
