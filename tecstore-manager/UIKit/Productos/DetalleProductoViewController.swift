import UIKit

final class DetalleProductoViewController: UIViewController {

    // MARK: - Data
    var producto: Producto!

    // MARK: - IBOutlets (storyboard-placed, styled in code)
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var nombreLabel: UILabel!
    @IBOutlet weak var precioLabel: UILabel!
    @IBOutlet weak var stockBadge: UILabel!
    @IBOutlet weak var estadoBadge: UILabel!

    // MARK: - UI (programmatic — not IBOutlets)
    private let subtitleLabel  = UILabel()

    // Info card
    private let infoCard         = UIView()
    private let precioTitleLabel = UILabel()
    private let cardDiv1         = UIView()
    private let estadoTitleLabel = UILabel()
    private let cardDiv2         = UIView()
    private let fechaLabel       = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupIBOutletStyling()
        setupProgrammaticViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let updated = ProductoService.shared.fetch(byID: producto.id) { producto = updated }
        populate()
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .appBackground
        title = "Detalle del producto"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Editar", style: .plain, target: self, action: #selector(editProduct))
    }

    /// Apply styling to IBOutlet views without adding or constraining them (storyboard owns layout).
    private func setupIBOutletStyling() {
        photoImageView.contentMode     = .scaleAspectFill
        photoImageView.clipsToBounds   = true
        photoImageView.backgroundColor = .appSurface

        nombreLabel.font          = AppFont.title2()
        nombreLabel.textColor     = .appTextPrimary
        nombreLabel.numberOfLines = 2

        precioLabel.font      = AppFont.title3()
        precioLabel.textColor = .brandPrimary

        for badge in ([stockBadge, estadoBadge] as [UILabel]) {
            badge.font               = AppFont.caption1()
            badge.textColor          = .white
            badge.textAlignment      = .center
            badge.layer.cornerRadius = 10
            badge.clipsToBounds      = true
        }
    }

    /// Add programmatic supplementary views (subtitleLabel, infoCard, etc.) to the storyboard's
    /// contentView. `nombreLabel.superview` is the storyboard-provided contentView.
    private func setupProgrammaticViews() {
        guard let contentView = nombreLabel.superview else { return }
        let p  = AppLayout.padding
        let ph = AppLayout.paddingLarge

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font      = AppFont.footnote()
        subtitleLabel.textColor = .appTextSecondary
        contentView.addSubview(subtitleLabel)

        // Info card container
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        infoCard.backgroundColor    = .appSurface
        infoCard.layer.cornerRadius = AppLayout.cornerRadius
        infoCard.layer.cornerCurve  = .continuous

        // Row title labels
        for (lbl, text) in [(precioTitleLabel, "Precio"), (estadoTitleLabel, "Estado")] {
            lbl.translatesAutoresizingMaskIntoConstraints = false
            lbl.text      = text
            lbl.font      = AppFont.subheadline()
            lbl.textColor = .appTextSecondary
        }

        fechaLabel.translatesAutoresizingMaskIntoConstraints = false
        fechaLabel.font      = AppFont.footnote()
        fechaLabel.textColor = .appTextTertiary

        // Dividers
        for div in [cardDiv1, cardDiv2] {
            div.translatesAutoresizingMaskIntoConstraints = false
            div.backgroundColor = .appSeparator
        }

        // IBOutlet badges go inside infoCard
        stockBadge.translatesAutoresizingMaskIntoConstraints = false
        estadoBadge.translatesAutoresizingMaskIntoConstraints = false

        infoCard.addSubviews(
            precioTitleLabel, precioLabel, stockBadge,
            cardDiv1,
            estadoTitleLabel, estadoBadge,
            cardDiv2,
            fechaLabel
        )
        contentView.addSubview(infoCard)

        NSLayoutConstraint.activate([
            // Subtitle below nombreLabel (IBOutlet)
            subtitleLabel.topAnchor.constraint(equalTo: nombreLabel.bottomAnchor, constant: 6),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),

            // Info card below subtitle
            infoCard.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: ph),
            infoCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            infoCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),
            infoCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -ph),

            // Row 1: Precio title | precioLabel (IBOutlet) | stockBadge (IBOutlet)
            precioTitleLabel.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: p),
            precioTitleLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: p),
            precioTitleLabel.bottomAnchor.constraint(equalTo: cardDiv1.topAnchor, constant: -p),

            precioLabel.centerYAnchor.constraint(equalTo: precioTitleLabel.centerYAnchor),
            precioLabel.leadingAnchor.constraint(equalTo: precioTitleLabel.trailingAnchor, constant: p),

            stockBadge.centerYAnchor.constraint(equalTo: precioTitleLabel.centerYAnchor),
            stockBadge.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -p),
            stockBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 90),
            stockBadge.heightAnchor.constraint(equalToConstant: 26),

            // Divider 1
            cardDiv1.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor),
            cardDiv1.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            cardDiv1.heightAnchor.constraint(equalToConstant: 1),

            // Row 2: Estado title | estadoBadge (IBOutlet)
            estadoTitleLabel.topAnchor.constraint(equalTo: cardDiv1.bottomAnchor, constant: p),
            estadoTitleLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: p),
            estadoTitleLabel.bottomAnchor.constraint(equalTo: cardDiv2.topAnchor, constant: -p),

            estadoBadge.centerYAnchor.constraint(equalTo: estadoTitleLabel.centerYAnchor),
            estadoBadge.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -p),
            estadoBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 70),
            estadoBadge.heightAnchor.constraint(equalToConstant: 26),

            // Divider 2
            cardDiv2.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor),
            cardDiv2.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            cardDiv2.heightAnchor.constraint(equalToConstant: 1),

            // Fecha
            fechaLabel.topAnchor.constraint(equalTo: cardDiv2.bottomAnchor, constant: p),
            fechaLabel.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: p),
            fechaLabel.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -p),
            fechaLabel.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -p),
        ])
    }

    // MARK: - Populate

    private func populate() {
        guard let p = producto else { return }

        let placeholder = UIImage(systemName: "shippingbox.fill")?.withRenderingMode(.alwaysTemplate)
        photoImageView.setImage(from: p.productImagePath, placeholder: placeholder)
        photoImageView.tintColor = p.productImagePath == nil ? .appTextTertiary : nil

        nombreLabel.text   = p.productName
        subtitleLabel.text = "\(p.productCode)  ·  \(p.categoryValue)"
        precioLabel.text   = p.priceDouble.asCurrency

        let stockInt = p.stockInt
        stockBadge.text            = "  \(stockInt) \(stockInt == 1 ? "unidad" : "unidades")  "
        stockBadge.backgroundColor = stockInt.stockUIColor

        let active = p.isActive
        estadoBadge.text            = "  \(p.statusValue)  "
        estadoBadge.backgroundColor = active ? .appSuccess : .appTextSecondary

        fechaLabel.text = "Registrado el \(p.registrationDate.displayDate)"
    }

    // MARK: - Actions

    @objc private func editProduct() {
        performSegue(withIdentifier: "showEditarProducto", sender: producto)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEditarProducto",
           let dest = segue.destination as? FormularioProductoViewController,
           let p = sender as? Producto {
            dest.producto = p
            dest.onSave   = { }
        }
    }
}
