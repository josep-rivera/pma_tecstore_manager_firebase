import UIKit
import MapKit

final class DetalleClienteViewController: UIViewController {

    // MARK: - Data
    var cliente: FBCliente!

    // MARK: - IBOutlets (storyboard-placed, styled in code)
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusBadge: UILabel!
    @IBOutlet weak var dniLabel: UILabel!
    @IBOutlet weak var telefonoLabel: UILabel!
    @IBOutlet weak var correoLabel: UILabel!
    @IBOutlet weak var direccionLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!

    // MARK: - UI (programmatic — not IBOutlets)
    // Header
    private let avatarView   = UIView()
    private let avatarLetter = UILabel()

    // Contact card
    private let contactCard    = UIView()
    private let contactDiv1    = UIView()
    private let contactDiv2    = UIView()
    private let contactDiv3    = UIView()
    private let contactDiv4    = UIView()
    private let fechaLabel     = UILabel()

    // Map supporting
    private let noLocationLabel = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupIBOutletStyling()
        setupProgrammaticViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        populate()
        Task { if let updated = try? await ClienteService.shared.fetch(byID: cliente.id ?? "") { await MainActor.run { self.cliente = updated; self.populate() } } }
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .appBackground
        title = "Detalle del cliente"
        navigationItem.largeTitleDisplayMode = .never
    }

    /// Apply styling to IBOutlet views without adding or constraining them (storyboard owns layout).
    private func setupIBOutletStyling() {
        nameLabel.font          = AppFont.title2()
        nameLabel.textColor     = .appTextPrimary
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 0

        statusBadge.font               = AppFont.caption1()
        statusBadge.textColor          = .white
        statusBadge.textAlignment      = .center
        statusBadge.layer.cornerRadius = 12
        statusBadge.clipsToBounds      = true
        statusBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 72).isActive = true
        statusBadge.heightAnchor.constraint(equalToConstant: 24).isActive = true

        for lbl in ([dniLabel, telefonoLabel, correoLabel, direccionLabel] as [UILabel]) {
            lbl.font          = AppFont.body()
            lbl.textColor     = .appTextSecondary
            lbl.numberOfLines = 0
        }

        mapView.layer.cornerRadius       = AppLayout.cornerRadius
        mapView.layer.cornerCurve        = .continuous
        mapView.clipsToBounds            = true
        mapView.isUserInteractionEnabled = false
    }

    /// Add programmatic supplementary views to the storyboard's contentView.
    /// `nameLabel.superview` is the storyboard-provided contentView inside the scrollView.
    private func setupProgrammaticViews() {
        guard let contentView = nameLabel.superview else { return }
        let ph = AppLayout.paddingLarge
        let p  = AppLayout.padding

        // Avatar (96pt) — programmatic, positioned above nameLabel
        let avatarSize: CGFloat = 96
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.layer.cornerRadius = avatarSize / 2
        avatarView.backgroundColor    = .brandLight
        avatarView.constrainSize(width: avatarSize, height: avatarSize)

        avatarLetter.translatesAutoresizingMaskIntoConstraints = false
        avatarLetter.font          = AppFont.title1()
        avatarLetter.textColor     = .brandPrimary
        avatarLetter.textAlignment = .center
        avatarView.addSubview(avatarLetter)
        avatarLetter.pinEdges(to: avatarView)

        contentView.addSubview(avatarView)
        contentView.insertSubview(avatarView, belowSubview: nameLabel)

        // Contact card (programmatic), wrapping the IBOutlet contact labels
        contactCard.translatesAutoresizingMaskIntoConstraints = false
        contactCard.backgroundColor    = .appSurface
        contactCard.layer.cornerRadius = AppLayout.cornerRadius
        contactCard.layer.cornerCurve  = .continuous

        fechaLabel.translatesAutoresizingMaskIntoConstraints = false
        fechaLabel.font      = AppFont.footnote()
        fechaLabel.textColor = .appTextTertiary

        for div in [contactDiv1, contactDiv2, contactDiv3, contactDiv4] {
            div.translatesAutoresizingMaskIntoConstraints = false
            div.backgroundColor = .appSeparator
        }

        // Reparent IBOutlet labels into contactCard
        for lbl in ([dniLabel, telefonoLabel, correoLabel, direccionLabel] as [UILabel]) {
            lbl.translatesAutoresizingMaskIntoConstraints = false
            contactCard.addSubview(lbl)
        }

        contactCard.addSubviews(
            contactDiv1,
            contactDiv2,
            contactDiv3,
            contactDiv4,
            fechaLabel
        )
        contentView.addSubview(contactCard)

        // Map already in contentView via storyboard; reparent mapView is not needed.
        // noLocationLabel goes on top of mapView
        noLocationLabel.translatesAutoresizingMaskIntoConstraints = false
        noLocationLabel.text          = "Sin ubicación registrada"
        noLocationLabel.font          = AppFont.footnote()
        noLocationLabel.textColor     = .appTextTertiary
        noLocationLabel.textAlignment = .center
        contentView.addSubview(noLocationLabel)

        NSLayoutConstraint.activate([
            // Avatar above nameLabel (nameLabel is at top+120 per storyboard; we insert avatar above it)
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ph),
            avatarView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            // Contact card below statusBadge (IBOutlet)
            contactCard.topAnchor.constraint(equalTo: statusBadge.bottomAnchor, constant: ph),
            contactCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            contactCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),

            // DNI row (IBOutlet)
            dniLabel.topAnchor.constraint(equalTo: contactCard.topAnchor, constant: p),
            dniLabel.leadingAnchor.constraint(equalTo: contactCard.leadingAnchor, constant: p),
            dniLabel.trailingAnchor.constraint(equalTo: contactCard.trailingAnchor, constant: -p),

            contactDiv1.topAnchor.constraint(equalTo: dniLabel.bottomAnchor, constant: p),
            contactDiv1.leadingAnchor.constraint(equalTo: contactCard.leadingAnchor),
            contactDiv1.trailingAnchor.constraint(equalTo: contactCard.trailingAnchor),
            contactDiv1.heightAnchor.constraint(equalToConstant: 1),

            // Teléfono row (IBOutlet)
            telefonoLabel.topAnchor.constraint(equalTo: contactDiv1.bottomAnchor, constant: p),
            telefonoLabel.leadingAnchor.constraint(equalTo: contactCard.leadingAnchor, constant: p),
            telefonoLabel.trailingAnchor.constraint(equalTo: contactCard.trailingAnchor, constant: -p),

            contactDiv2.topAnchor.constraint(equalTo: telefonoLabel.bottomAnchor, constant: p),
            contactDiv2.leadingAnchor.constraint(equalTo: contactCard.leadingAnchor),
            contactDiv2.trailingAnchor.constraint(equalTo: contactCard.trailingAnchor),
            contactDiv2.heightAnchor.constraint(equalToConstant: 1),

            // Correo row (IBOutlet)
            correoLabel.topAnchor.constraint(equalTo: contactDiv2.bottomAnchor, constant: p),
            correoLabel.leadingAnchor.constraint(equalTo: contactCard.leadingAnchor, constant: p),
            correoLabel.trailingAnchor.constraint(equalTo: contactCard.trailingAnchor, constant: -p),

            contactDiv3.topAnchor.constraint(equalTo: correoLabel.bottomAnchor, constant: p),
            contactDiv3.leadingAnchor.constraint(equalTo: contactCard.leadingAnchor),
            contactDiv3.trailingAnchor.constraint(equalTo: contactCard.trailingAnchor),
            contactDiv3.heightAnchor.constraint(equalToConstant: 1),

            // Dirección row (IBOutlet)
            direccionLabel.topAnchor.constraint(equalTo: contactDiv3.bottomAnchor, constant: p),
            direccionLabel.leadingAnchor.constraint(equalTo: contactCard.leadingAnchor, constant: p),
            direccionLabel.trailingAnchor.constraint(equalTo: contactCard.trailingAnchor, constant: -p),

            contactDiv4.topAnchor.constraint(equalTo: direccionLabel.bottomAnchor, constant: p),
            contactDiv4.leadingAnchor.constraint(equalTo: contactCard.leadingAnchor),
            contactDiv4.trailingAnchor.constraint(equalTo: contactCard.trailingAnchor),
            contactDiv4.heightAnchor.constraint(equalToConstant: 1),

            // Fecha (programmatic)
            fechaLabel.topAnchor.constraint(equalTo: contactDiv4.bottomAnchor, constant: p),
            fechaLabel.leadingAnchor.constraint(equalTo: contactCard.leadingAnchor, constant: p),
            fechaLabel.trailingAnchor.constraint(equalTo: contactCard.trailingAnchor, constant: -p),
            fechaLabel.bottomAnchor.constraint(equalTo: contactCard.bottomAnchor, constant: -p),

            // mapView (IBOutlet) — storyboard placed it in contentView; add constraints for card→map
            mapView.topAnchor.constraint(equalTo: contactCard.bottomAnchor, constant: ph),
            mapView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            mapView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),
            mapView.heightAnchor.constraint(equalToConstant: 200),
            mapView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -ph),

            noLocationLabel.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            noLocationLabel.centerYAnchor.constraint(equalTo: mapView.centerYAnchor),
        ])
    }

    // MARK: - Populate

    private func iconText(_ label: UILabel, icon: String, text: String) {
        guard let img = UIImage(systemName: icon)?
            .withTintColor(.appTextSecondary, renderingMode: .alwaysOriginal)
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 15, weight: .regular)) else {
            label.text = text; return
        }
        let attach    = NSTextAttachment()
        attach.image  = img
        attach.bounds = CGRect(x: 0, y: -3, width: 17, height: 17)
        let full      = NSMutableAttributedString(attachment: attach)
        full.append(NSAttributedString(
            string:     "  \(text)",
            attributes: [.font: AppFont.body(), .foregroundColor: UIColor.appTextSecondary]
        ))
        label.attributedText = full
    }

    private func populate() {
        guard let c = cliente else { return }

        let initial       = c.firstNames.first.map { String($0) } ?? "?"
        avatarLetter.text = initial.uppercased()
        nameLabel.text    = c.fullName

        statusBadge.text            = c.statusValue
        statusBadge.backgroundColor = c.isActive ? .appSuccess : .appTextSecondary

        iconText(dniLabel,       icon: "creditcard",    text: "DNI: \(c.dniValue)")
        iconText(telefonoLabel,  icon: "phone",         text: c.phoneNumber  ?? "Sin teléfono")
        iconText(correoLabel,    icon: "envelope",      text: c.emailValue   ?? "Sin correo")
        iconText(direccionLabel, icon: "mappin.circle", text: c.addressValue ?? "Sin dirección")
        fechaLabel.text = "Registrado el \(c.registrationDate.displayDate)"

        if c.hasValidCoordinates {
            noLocationLabel.isHidden = true
            let coord    = CLLocationCoordinate2D(latitude: c.latitude, longitude: c.longitude)
            let pin      = MKPointAnnotation()
            pin.title    = c.fullName
            pin.subtitle = c.locationReference
            pin.coordinate = coord
            mapView.removeAnnotations(mapView.annotations)
            mapView.addAnnotation(pin)
            let region = MKCoordinateRegion(center: coord,
                                            latitudinalMeters: 1500, longitudinalMeters: 1500)
            mapView.setRegion(region, animated: false)
        } else {
            noLocationLabel.isHidden = false
            mapView.removeAnnotations(mapView.annotations)
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dest = segue.destination as? FormularioClienteViewController {
            dest.cliente = cliente
            dest.onSave  = { }
        }
    }
}
