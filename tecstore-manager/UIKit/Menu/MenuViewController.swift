import UIKit
import SwiftUI

final class MenuViewController: UITabBarController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        applyNavBarAppearance()
        setupTabBarItems()
    }

    private func setupTabBarItems() {
        let configs: [(String, String)] = [
            ("Inicio",     "house.fill"),
            ("Productos",  "shippingbox.fill"),
            ("Clientes",   "person.2.fill"),
            ("Ventas",     "cart.fill"),
            ("Perfil",     "person.circle.fill")
        ]
        for (index, (title, icon)) in configs.enumerated() {
            guard let vcs = viewControllers, index < vcs.count else { continue }
            vcs[index].tabBarItem.title = title
            vcs[index].tabBarItem.image = UIImage(systemName: icon)
        }
    }

    // MARK: - Appearance

    private func applyNavBarAppearance() {
        for vc in viewControllers ?? [] {
            guard let nav = vc as? UINavigationController else { continue }
            forceOpaqueNavBar(nav)
        }
    }

    private func forceOpaqueNavBar(_ nav: UINavigationController) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .appBackground
        appearance.shadowColor     = .appSeparator
        appearance.titleTextAttributes = [
            .font:            AppFont.headline(),
            .foregroundColor: UIColor.appTextPrimary
        ]
        nav.navigationBar.standardAppearance          = appearance
        nav.navigationBar.scrollEdgeAppearance        = appearance
        nav.navigationBar.compactAppearance           = appearance
        nav.navigationBar.compactScrollEdgeAppearance = appearance
        nav.navigationBar.tintColor                   = .brandPrimary
    }
}
