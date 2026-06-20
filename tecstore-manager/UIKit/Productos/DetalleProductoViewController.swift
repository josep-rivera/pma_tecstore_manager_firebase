import UIKit

final class DetalleProductoViewController: UIViewController {

    // MARK: - Data
    var producto: FBProducto!

    // MARK: - IBOutlets
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var nombreLabel:    UILabel!
    @IBOutlet weak var precioLabel:    UILabel!
    @IBOutlet weak var stockBadge:     UILabel!
    @IBOutlet weak var estadoBadge:    UILabel!

    // MARK: - UI (programmatic)
    private let codeLabel     = UILabel()
    private let infoCard      = UIView()
    private let stockRow      = InfoRow()
    private let estadoRow     = InfoRow()
    private let codigoRow     = InfoRow()
    private let categoriaRow  = InfoRow()
    private let fechaRow      = InfoRow()
    private let div1 = UIView(), div2 = UIView(), div3 = UIView(), div4 = UIView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupIBOutletStyling()
        setupProgrammaticViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        populate()
        Task { if let updated = try? await ProductoService.shared.fetch(byID: producto.id ?? "") { await MainActor.run { self.producto = updated; self.populate() } } }
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .appBackground
        title = "Detalle del producto"
        navigationItem.largeTitleDisplayMode = .never
    }

    private func setupIBOutletStyling() {
        photoImageView.contentMode     = .scaleAspectFit
        photoImageView.clipsToBounds   = true
        photoImageView.backgroundColor = .appSurface

        nombreLabel.font          = .systemFont(ofSize: 20, weight: .bold)
        nombreLabel.textColor     = .appTextPrimary
        nombreLabel.numberOfLines = 2

        // precioLabel, stockBadge, estadoBadge are now unused as IBOutlets for display —
        // they're hidden; InfoRows in the programmatic card handle display.
        precioLabel.isHidden  = true
        stockBadge.isHidden   = true
        estadoBadge.isHidden  = true
    }

    private func setupProgrammaticViews() {
        guard let contentView = nombreLabel.superview else { return }
        let ph = AppLayout.paddingLarge
        let p  = AppLayout.padding

        // Code/category subtitle below nombreLabel
        codeLabel.translatesAutoresizingMaskIntoConstraints = false
        codeLabel.font      = .systemFont(ofSize: 13, weight: .regular)
        codeLabel.textColor = .appTextSecondary
        contentView.addSubview(codeLabel)

        // Card
        infoCard.translatesAutoresizingMaskIntoConstraints = false
        infoCard.backgroundColor    = .appSurface
        infoCard.layer.cornerRadius = AppLayout.cornerRadius
        infoCard.layer.cornerCurve  = .continuous
        contentView.addSubview(infoCard)

        let rows: [InfoRow] = [stockRow, estadoRow, codigoRow, categoriaRow, fechaRow]
        let divs: [UIView]  = [div1, div2, div3, div4]
        for row in rows { row.translatesAutoresizingMaskIntoConstraints = false; infoCard.addSubview(row) }
        for div in divs { div.translatesAutoresizingMaskIntoConstraints = false; div.backgroundColor = .appSeparator; infoCard.addSubview(div) }

        NSLayoutConstraint.activate([
            codeLabel.topAnchor.constraint(equalTo: nombreLabel.bottomAnchor, constant: 4),
            codeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            codeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),

            infoCard.topAnchor.constraint(equalTo: codeLabel.bottomAnchor, constant: ph),
            infoCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            infoCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),
            infoCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -ph),
        ])

        // Stack rows inside infoCard with dividers
        NSLayoutConstraint.activate([
            stockRow.topAnchor.constraint(equalTo: infoCard.topAnchor),
            stockRow.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor),
            stockRow.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            stockRow.heightAnchor.constraint(equalToConstant: 48),

            div1.topAnchor.constraint(equalTo: stockRow.bottomAnchor),
            div1.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: p),
            div1.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            div1.heightAnchor.constraint(equalToConstant: 0.5),

            estadoRow.topAnchor.constraint(equalTo: div1.bottomAnchor),
            estadoRow.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor),
            estadoRow.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            estadoRow.heightAnchor.constraint(equalToConstant: 48),

            div2.topAnchor.constraint(equalTo: estadoRow.bottomAnchor),
            div2.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: p),
            div2.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            div2.heightAnchor.constraint(equalToConstant: 0.5),

            codigoRow.topAnchor.constraint(equalTo: div2.bottomAnchor),
            codigoRow.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor),
            codigoRow.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            codigoRow.heightAnchor.constraint(equalToConstant: 48),

            div3.topAnchor.constraint(equalTo: codigoRow.bottomAnchor),
            div3.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: p),
            div3.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            div3.heightAnchor.constraint(equalToConstant: 0.5),

            categoriaRow.topAnchor.constraint(equalTo: div3.bottomAnchor),
            categoriaRow.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor),
            categoriaRow.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            categoriaRow.heightAnchor.constraint(equalToConstant: 48),

            div4.topAnchor.constraint(equalTo: categoriaRow.bottomAnchor),
            div4.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: p),
            div4.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            div4.heightAnchor.constraint(equalToConstant: 0.5),

            fechaRow.topAnchor.constraint(equalTo: div4.bottomAnchor),
            fechaRow.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor),
            fechaRow.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor),
            fechaRow.heightAnchor.constraint(equalToConstant: 48),
            fechaRow.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor),
        ])
    }

    // MARK: - Populate

    private func populate() {
        guard let p = producto else { return }

        let placeholder = UIImage(systemName: "shippingbox")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 40, weight: .light))
            .withRenderingMode(.alwaysTemplate)
        photoImageView.setImage(from: p.productImagePath, placeholder: placeholder)
        photoImageView.tintColor = p.productImagePath == nil ? .appTextTertiary : nil
        if p.productImagePath != nil { photoImageView.contentMode = .scaleAspectFill }

        nombreLabel.text = p.productName
        codeLabel.text   = "\(p.productCode)  ·  \(p.categoryValue)"

        let stockInt = p.stockInt
        stockRow.configure(
            icon:  "shippingbox",
            title: "Stock",
            value: "\(stockInt) \(stockInt == 1 ? "unidad" : "unidades")",
            valueColor: stockInt.stockUIColor
        )
        estadoRow.configure(
            icon:  p.isActive ? "checkmark.circle" : "xmark.circle",
            title: "Estado",
            value: p.statusValue,
            valueColor: p.isActive ? .appSuccess : .appTextSecondary
        )
        codigoRow.configure(icon: "barcode", title: "Código", value: p.productCode)
        categoriaRow.configure(icon: "tag", title: "Categoría", value: p.categoryValue)
        fechaRow.configure(icon: "calendar", title: "Registrado", value: p.registrationDate.displayDate)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? FormularioProductoViewController {
            dest.producto = producto
            dest.onSave   = { }
        }
    }
}

// MARK: - InfoRow

private final class InfoRow: UIView {

    private let iconView  = UIImageView()
    private let titleLbl  = UILabel()
    private let valueLbl  = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        iconView.translatesAutoresizingMaskIntoConstraints  = false
        titleLbl.translatesAutoresizingMaskIntoConstraints  = false
        valueLbl.translatesAutoresizingMaskIntoConstraints  = false

        iconView.tintColor      = .appTextTertiary
        iconView.contentMode    = .scaleAspectFit

        titleLbl.font           = .systemFont(ofSize: 15, weight: .regular)
        titleLbl.textColor      = .appTextSecondary

        valueLbl.font           = .systemFont(ofSize: 15, weight: .medium)
        valueLbl.textColor      = .appTextPrimary
        valueLbl.textAlignment  = .right
        valueLbl.numberOfLines  = 1
        valueLbl.adjustsFontSizeToFitWidth = true
        valueLbl.minimumScaleFactor = 0.8

        addSubview(iconView); addSubview(titleLbl); addSubview(valueLbl)

        let p: CGFloat = 16
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: p),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            titleLbl.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 10),
            titleLbl.centerYAnchor.constraint(equalTo: centerYAnchor),

            valueLbl.leadingAnchor.constraint(equalTo: titleLbl.trailingAnchor, constant: 8),
            valueLbl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -p),
            valueLbl.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(icon: String, title: String, value: String, valueColor: UIColor = .appTextPrimary) {
        iconView.image  = UIImage(systemName: icon)?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 14, weight: .regular))
        titleLbl.text   = title
        valueLbl.text   = value
        valueLbl.textColor = valueColor
    }
}
