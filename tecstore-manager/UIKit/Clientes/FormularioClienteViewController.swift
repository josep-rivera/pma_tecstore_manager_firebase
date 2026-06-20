import UIKit
import MapKit
import CoreLocation

final class FormularioClienteViewController: UIViewController {

    // MARK: - Mode
    var cliente: FBCliente?
    var onSave:  (() -> Void)?

    private var isEditMode: Bool { cliente != nil }
    private var selectedLatitude:  Double = 0
    private var selectedLongitude: Double = 0
    private var selectedAnnotation = MKPointAnnotation()

    private var activeSearch: MKLocalSearch?
    private var geocodeTimer: Timer?

    // MARK: - IBOutlets
    @IBOutlet weak var dniField: UITextField!
    @IBOutlet weak var nombresField: UITextField!
    @IBOutlet weak var apellidosField: UITextField!
    @IBOutlet weak var telefonoField: UITextField!
    @IBOutlet weak var correoField: UITextField!
    @IBOutlet weak var direccionField: UITextField!
    @IBOutlet weak var estadoSwitch: UISwitch!
    @IBOutlet weak var mapView: MKMapView!

    // MARK: - UI
    private let dniError       = AppStyle.makeErrorLabel()
    private let nombresError   = AppStyle.makeErrorLabel()
    private let apellidosError = AppStyle.makeErrorLabel()
    private let correoError    = AppStyle.makeErrorLabel()

    private let estadoLabel      = AppStyle.makeFieldLabel("Estado")
    private let estadoValueLabel = UILabel()

    private let locationHeaderLabel  = UILabel()
    private let mapHintLabel         = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupFields()
        setupEstado()
        setupLocationSection()
        setupProgrammaticViews()
        setupKeyboard()
        if isEditMode { populateFields() } else { navigationItem.rightBarButtonItem?.isEnabled = false }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            let tabBarHeight = tabBarController?.tabBar.frame.height ?? 0
            if scrollView.contentInset.bottom == 0 {
                scrollView.contentInset.bottom = tabBarHeight + AppLayout.padding
                scrollView.verticalScrollIndicatorInsets.bottom = tabBarHeight
            }
        }
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .appBackground
        title = isEditMode ? "Editar cliente" : "Nuevo cliente"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Guardar", style: .prominent, target: self, action: #selector(handleSave))
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapToDismiss))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setupFields() {
        let configs: [(UITextField, String, String, UIKeyboardType, UIReturnKeyType, Bool)] = [
            (dniField,       "DNI (8 dígitos)",       "creditcard",  .numberPad,    .next, false),
            (nombresField,   "Nombres",                "person",      .default,      .next, false),
            (apellidosField, "Apellidos",              "person.fill", .default,      .next, false),
            (telefonoField,  "Teléfono (opcional)",    "phone",       .phonePad,     .next, false),
            (correoField,    "Correo (opcional)",      "envelope",    .emailAddress, .next, false),
            (direccionField, "Dirección (opcional)",   "mappin",      .default,      .done, false)
        ]
        for (field, ph, icon, kb, ret, sec) in configs {
            AppStyle.style(textField: field, placeholder: ph, icon: icon,
                           isSecure: sec, keyboardType: kb, returnKey: ret)
            field.delegate = self
            field.addTarget(self, action: #selector(fieldsChanged), for: .editingChanged)
        }
        nombresField.autocapitalizationType   = .words
        apellidosField.autocapitalizationType = .words
        direccionField.autocapitalizationType = .words
        dniField.addTarget(self, action: #selector(dniChanged), for: .editingChanged)
        direccionField.addTarget(self, action: #selector(direccionChanged), for: .editingChanged)
    }

    private func setupEstado() {
        estadoSwitch.isOn       = true
        estadoSwitch.onTintColor = .appSuccess
        estadoSwitch.addTarget(self, action: #selector(estadoChanged), for: .valueChanged)

        estadoValueLabel.translatesAutoresizingMaskIntoConstraints = false
        estadoValueLabel.font      = AppFont.subheadline()
        estadoValueLabel.textColor = .appSuccess
        estadoValueLabel.text      = "Activo"
    }

    private func setupLocationSection() {
        mapView.layer.cornerRadius = AppLayout.cornerRadius
        mapView.clipsToBounds      = true
        mapView.delegate           = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(mapTapped(_:)))
        mapView.addGestureRecognizer(tap)
    }

    /// Add programmatic error labels, estado row, and location header+hint to the storyboard contentView.
    /// `dniField.superview` is the storyboard-provided contentView inside the scrollView.
    private func setupProgrammaticViews() {
        guard let contentView = dniField.superview else { return }
        let ph = AppLayout.paddingLarge
        let p  = AppLayout.padding

        for label in [dniError, nombresError, apellidosError, correoError] {
            label.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(label)
        }

        estadoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(estadoLabel)
        contentView.addSubview(estadoValueLabel)

        locationHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        locationHeaderLabel.text      = "Ubicación del cliente"
        locationHeaderLabel.font      = AppFont.headline()
        locationHeaderLabel.textColor = .appTextPrimary
        contentView.addSubview(locationHeaderLabel)

        mapHintLabel.translatesAutoresizingMaskIntoConstraints = false
        mapHintLabel.text          = "Toca el mapa para colocar el pin"
        mapHintLabel.font          = AppFont.caption1()
        mapHintLabel.textColor     = .appTextSecondary
        mapHintLabel.textAlignment = .center
        contentView.addSubview(mapHintLabel)

        NSLayoutConstraint.activate([
            dniError.topAnchor.constraint(equalTo: dniField.bottomAnchor, constant: 4),
            dniError.leadingAnchor.constraint(equalTo: dniField.leadingAnchor),
            dniError.trailingAnchor.constraint(equalTo: dniField.trailingAnchor),

            nombresError.topAnchor.constraint(equalTo: nombresField.bottomAnchor, constant: 4),
            nombresError.leadingAnchor.constraint(equalTo: nombresField.leadingAnchor),
            nombresError.trailingAnchor.constraint(equalTo: nombresField.trailingAnchor),

            apellidosError.topAnchor.constraint(equalTo: apellidosField.bottomAnchor, constant: 4),
            apellidosError.leadingAnchor.constraint(equalTo: apellidosField.leadingAnchor),
            apellidosError.trailingAnchor.constraint(equalTo: apellidosField.trailingAnchor),

            correoError.topAnchor.constraint(equalTo: correoField.bottomAnchor, constant: 4),
            correoError.leadingAnchor.constraint(equalTo: correoField.leadingAnchor),
            correoError.trailingAnchor.constraint(equalTo: correoField.trailingAnchor),

            estadoLabel.topAnchor.constraint(equalTo: direccionField.bottomAnchor, constant: p + 4),
            estadoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            estadoSwitch.centerYAnchor.constraint(equalTo: estadoLabel.centerYAnchor),
            estadoSwitch.leadingAnchor.constraint(equalTo: estadoLabel.trailingAnchor, constant: p),
            estadoValueLabel.centerYAnchor.constraint(equalTo: estadoSwitch.centerYAnchor),
            estadoValueLabel.leadingAnchor.constraint(equalTo: estadoSwitch.trailingAnchor, constant: p),

            locationHeaderLabel.topAnchor.constraint(equalTo: estadoLabel.bottomAnchor, constant: ph),
            locationHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),

            mapView.topAnchor.constraint(equalTo: locationHeaderLabel.bottomAnchor, constant: p),
            mapView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            mapView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),
            mapView.heightAnchor.constraint(equalToConstant: 200),

            mapHintLabel.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 6),
            mapHintLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            mapHintLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),
            mapHintLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -p),
        ])
    }

    private func setupKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        geocodeTimer?.invalidate()
        activeSearch?.cancel()
    }

    // MARK: - Populate

    private func populateFields() {
        guard let c = cliente else { return }
        dniField.text       = c.dniValue
        nombresField.text   = c.firstNames
        apellidosField.text = c.lastNames
        telefonoField.text  = c.phoneNumber
        correoField.text    = c.emailValue
        direccionField.text = c.addressValue
        estadoSwitch.isOn   = c.isActive
        updateEstadoLabel()

        if c.hasValidCoordinates {
            setMapPin(lat: c.latitude, lon: c.longitude)
        } else {
            centerMapOnLima()
        }
    }

    // MARK: - Map Helpers

    private func setMapPin(lat: Double, lon: Double) {
        selectedLatitude  = lat
        selectedLongitude = lon
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        selectedAnnotation.coordinate = coord
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(selectedAnnotation)
        let region = MKCoordinateRegion(center: coord,
                                        latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
    }

    private func centerMapOnLima() {
        let lima   = CLLocationCoordinate2D(latitude: -12.0464, longitude: -77.0428)
        let region = MKCoordinateRegion(center: lima,
                                        latitudinalMeters: 10_000, longitudinalMeters: 10_000)
        mapView.setRegion(region, animated: false)
    }

    // MARK: - Actions

    @objc private func handleSave() {
        guard validate() else { return }
        let dni       = dniField.text?.trimmed ?? ""
        let nombres   = nombresField.text?.trimmed ?? ""
        let apellidos = apellidosField.text?.trimmed ?? ""
        let telefono  = telefonoField.text
        let correo    = correoField.text
        let direccion = direccionField.text
        let estado    = estadoSwitch.isOn ? "Activo" : "Inactivo"
        let lat       = selectedLatitude
        let lon       = selectedLongitude
        let ref       = direccionField.text

        Task {
            do {
                let clienteID: String
                if self.isEditMode, let c = self.cliente {
                    try await ClienteService.shared.update(c, dni: dni, nombres: nombres,
                                                           apellidos: apellidos, telefono: telefono,
                                                           correo: correo, direccion: direccion,
                                                           estado: estado)
                    clienteID = c.id ?? ""
                } else {
                    clienteID = try await ClienteService.shared.create(
                        dni: dni, nombres: nombres, apellidos: apellidos,
                        telefono: telefono, correo: correo, direccion: direccion)
                }

                if lat != 0 || lon != 0 {
                    try await UbicacionService.shared.saveOrUpdate(
                        latitude: lat, longitude: lon,
                        reference: ref, clienteID: clienteID)
                }
                await MainActor.run {
                    self.onSave?()
                    self.navigationController?.popViewController(animated: true)
                }
            } catch let error as ServiceError {
                await MainActor.run { self.showAlert(title: "Error al guardar", message: error.errorDescription ?? "") }
            } catch {
                await MainActor.run { self.showAlert(title: "Error", message: error.localizedDescription) }
            }
        }
    }

    @objc private func mapTapped(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: mapView)
        let coord = mapView.convert(point, toCoordinateFrom: mapView)
        setMapPin(lat: coord.latitude, lon: coord.longitude)
        mapHintLabel.text      = "Pin colocado · toca para mover"
        mapHintLabel.textColor = .brandPrimary

        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        Task { [weak self] in
            guard let self else { return }
            guard let request = MKReverseGeocodingRequest(location: location),
                  let item = try? await request.mapItems.first else { return }
            let address = item.addressRepresentations?.fullAddress(includingRegion: false, singleLine: true) ?? ""
            if !address.isEmpty {
                await MainActor.run { self.direccionField.text = address }
            }
        }
    }

    @objc private func direccionChanged() {
        geocodeTimer?.invalidate()
        let text = direccionField.text?.trimmed ?? ""
        guard text.count > 6 else { return }
        geocodeTimer = Timer.scheduledTimer(withTimeInterval: 0.9, repeats: false) { [weak self] _ in
            self?.geocodeAddress(text)
        }
    }

    private func geocodeAddress(_ address: String) {
        activeSearch?.cancel()
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = address
        activeSearch = MKLocalSearch(request: request)
        activeSearch?.start { [weak self] response, _ in
            guard let item = response?.mapItems.first else { return }
            let coord = item.location.coordinate
            DispatchQueue.main.async {
                self?.setMapPin(lat: coord.latitude, lon: coord.longitude)
                self?.mapHintLabel.text      = "Ubicación encontrada"
                self?.mapHintLabel.textColor = .brandPrimary
            }
        }
    }

    @objc private func estadoChanged() { updateEstadoLabel() }
    private func updateEstadoLabel() {
        estadoValueLabel.text      = estadoSwitch.isOn ? "Activo" : "Inactivo"
        estadoValueLabel.textColor = estadoSwitch.isOn ? .appSuccess : .appTextSecondary
    }

    @objc private func fieldsChanged() { _ = validate() }
    @objc private func dniChanged() {
        if let text = dniField.text, text.count > 8 {
            dniField.text = String(text.prefix(8))
        }
        _ = validate()
    }
    @objc private func tapToDismiss() { view.endEditing(true) }

    @objc private func keyboardWillShow(_ n: NSNotification) {
        if let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
           let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.contentInset.bottom = frame.height + 20
        }
    }
    @objc private func keyboardWillHide(_ n: NSNotification) {
        if let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.contentInset.bottom = 0
        }
    }

    // MARK: - Validation

    @discardableResult
    private func validate() -> Bool {
        var valid = true

        let dni = dniField.text?.trimmed ?? ""
        if dni.isEmpty {
            setError(dniError, dniField, "El DNI es requerido.")
            valid = false
        } else if !dni.isValidDNI {
            setError(dniError, dniField, "El DNI debe tener exactamente 8 dígitos.")
            valid = false
        } else { clearError(dniError, dniField) }

        let nombres = nombresField.text?.trimmed ?? ""
        if nombres.isEmpty {
            setError(nombresError, nombresField, "Los nombres son requeridos.")
            valid = false
        } else { clearError(nombresError, nombresField) }

        let apellidos = apellidosField.text?.trimmed ?? ""
        if apellidos.isEmpty {
            setError(apellidosError, apellidosField, "Los apellidos son requeridos.")
            valid = false
        } else { clearError(apellidosError, apellidosField) }

        let correo = correoField.text?.trimmed ?? ""
        if correo.isNotBlank && !correo.isValidEmail {
            setError(correoError, correoField, "Formato de correo inválido.")
            valid = false
        } else { clearError(correoError, correoField) }

        navigationItem.rightBarButtonItem?.isEnabled = valid
        return valid
    }

    private func setError(_ l: UILabel, _ f: UITextField, _ m: String) {
        l.text = m; l.isHidden = false; AppStyle.markFieldError(f, hasError: true)
    }
    private func clearError(_ l: UILabel, _ f: UITextField) {
        l.isHidden = true; AppStyle.markFieldError(f, hasError: false)
    }
}

extension FormularioClienteViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case dniField:       nombresField.becomeFirstResponder()
        case nombresField:   apellidosField.becomeFirstResponder()
        case apellidosField: telefonoField.becomeFirstResponder()
        case telefonoField:  correoField.becomeFirstResponder()
        case correoField:    direccionField.becomeFirstResponder()
        default:             textField.resignFirstResponder()
        }
        return true
    }
}

extension FormularioClienteViewController: MKMapViewDelegate {}
