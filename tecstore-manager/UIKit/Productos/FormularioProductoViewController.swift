import UIKit
import PhotosUI

final class FormularioProductoViewController: UIViewController {

    // MARK: - Mode
    var producto: FBProducto?               // nil → create,  non-nil → edit
    var onSave: (() -> Void)?

    private var isEditMode: Bool { producto != nil }
    private var selectedPhotoPath: String?
    private var selectedCategory: String = ProductCategory.otros.rawValue
    private var generatedCode: String = ""

    // ── Category picker state
    private let categories = ProductCategory.allCases.map(\.rawValue)
    private var categoryPickerView = UIPickerView()

    // MARK: - IBOutlets
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var nombreField: UITextField!
    @IBOutlet weak var categoriaField: UITextField!
    @IBOutlet weak var precioField: UITextField!
    @IBOutlet weak var stockField: UITextField!
    @IBOutlet weak var estadoSwitch: UISwitch!

    // MARK: - UI (programmatic — not IBOutlets)
    private let nombreError     = AppStyle.makeErrorLabel()
    private let categoriaError  = AppStyle.makeErrorLabel()
    private let precioError     = AppStyle.makeErrorLabel()
    private let stockError      = AppStyle.makeErrorLabel()

    private let estadoLabel      = AppStyle.makeFieldLabel("Estado")
    private let estadoValueLabel = UILabel()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupPhoto()
        setupFields()
        setupEstado()
        setupProgrammaticViews()
        setupKeyboard()
        if isEditMode {
            populateFields()
        } else {
            refreshAutoCode()
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .appBackground
        title = isEditMode ? "Editar producto" : "Nuevo producto"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Guardar", style: .prominent, target: self, action: #selector(handleSave))
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapToDismiss))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setupPhoto() {
        photoImageView.contentMode        = .center
        photoImageView.clipsToBounds      = true
        photoImageView.layer.cornerRadius = AppLayout.cornerRadius
        photoImageView.layer.cornerCurve  = .continuous
        photoImageView.layer.borderWidth  = 1.5
        photoImageView.layer.borderColor  = UIColor.brandLight.cgColor
        photoImageView.backgroundColor    = .appSurface

        let cameraIcon = UIImage(systemName: "camera.fill")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 28, weight: .light))
            .withRenderingMode(.alwaysTemplate)
        photoImageView.image     = cameraIcon
        photoImageView.tintColor = .appTextTertiary

        photoButton.addTarget(self, action: #selector(handleSelectPhoto), for: .touchUpInside)
    }

    private func setupFields() {
        let configs: [(UITextField, String, String, UIKeyboardType, UIReturnKeyType)] = [
            (nombreField,    "Nombre del producto",   "tag",           .default,       .next),
            (precioField,    "0.00",                  "dollarsign.circle", .decimalPad, .done),
            (stockField,     "0",                     "number",        .numberPad,    .done)
        ]
        for (field, ph, icon, keyboard, ret) in configs {
            AppStyle.style(textField: field, placeholder: ph, icon: icon,
                           keyboardType: keyboard, returnKey: ret)
            field.delegate = self
            field.addTarget(self, action: #selector(fieldsChanged), for: .editingChanged)
        }
        nombreField.autocapitalizationType = .words

        // Categoria field with UIPickerView as inputView
        AppStyle.style(textField: categoriaField, placeholder: "Selecciona una categoría", icon: "tag.fill")
        categoriaField.text = selectedCategory
        categoriaField.tintColor = .clear   // hide cursor

        categoryPickerView.delegate   = self
        categoryPickerView.dataSource = self
        categoriaField.inputView      = categoryPickerView
        if let index = categories.firstIndex(of: selectedCategory) {
            categoryPickerView.selectRow(index, inComponent: 0, animated: false)
        }

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn   = UIBarButtonItem(title: "Listo", style: .prominent,
                                         target: self, action: #selector(categoryPickerDone))
        toolbar.setItems([flexSpace, doneBtn], animated: false)
        categoriaField.inputAccessoryView = toolbar
        categoriaField.addTarget(self, action: #selector(fieldsChanged), for: .editingChanged)
    }

    private func setupEstado() {
        estadoSwitch.isOn = true
        estadoSwitch.onTintColor = .appSuccess
        estadoSwitch.addTarget(self, action: #selector(estadoChanged), for: .valueChanged)

        estadoValueLabel.translatesAutoresizingMaskIntoConstraints = false
        estadoValueLabel.font      = AppFont.subheadline()
        estadoValueLabel.textColor = .appSuccess
        estadoValueLabel.text      = "Activo"
    }

    /// Add programmatic error labels and estado row to the storyboard contentView.
    /// `nombreField.superview` is the storyboard-provided contentView that holds all IBOutlet fields.
    private func setupProgrammaticViews() {
        guard let contentView = nombreField.superview else { return }
        let ph = AppLayout.paddingLarge
        let p  = AppLayout.padding

        for label in [nombreError, categoriaError, precioError, stockError] {
            label.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(label)
        }

        estadoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(estadoLabel)
        contentView.addSubview(estadoValueLabel)

        NSLayoutConstraint.activate([
            nombreError.topAnchor.constraint(equalTo: nombreField.bottomAnchor, constant: 4),
            nombreError.leadingAnchor.constraint(equalTo: nombreField.leadingAnchor),
            nombreError.trailingAnchor.constraint(equalTo: nombreField.trailingAnchor),

            categoriaError.topAnchor.constraint(equalTo: categoriaField.bottomAnchor, constant: 4),
            categoriaError.leadingAnchor.constraint(equalTo: categoriaField.leadingAnchor),
            categoriaError.trailingAnchor.constraint(equalTo: categoriaField.trailingAnchor),

            precioError.topAnchor.constraint(equalTo: precioField.bottomAnchor, constant: 4),
            precioError.leadingAnchor.constraint(equalTo: precioField.leadingAnchor),
            precioError.trailingAnchor.constraint(equalTo: precioField.trailingAnchor),

            stockError.topAnchor.constraint(equalTo: stockField.bottomAnchor, constant: 4),
            stockError.leadingAnchor.constraint(equalTo: stockField.leadingAnchor),
            stockError.trailingAnchor.constraint(equalTo: stockField.trailingAnchor),

            estadoLabel.topAnchor.constraint(equalTo: stockError.bottomAnchor, constant: p + 4),
            estadoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            estadoSwitch.centerYAnchor.constraint(equalTo: estadoLabel.centerYAnchor),
            estadoSwitch.leadingAnchor.constraint(equalTo: estadoLabel.trailingAnchor, constant: p),
            estadoValueLabel.centerYAnchor.constraint(equalTo: estadoSwitch.centerYAnchor),
            estadoValueLabel.leadingAnchor.constraint(equalTo: estadoSwitch.trailingAnchor, constant: p),
            estadoLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -p - 32),
        ])
    }

    private func setupKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Populate (edit mode)

    private func populateFields() {
        guard let p = producto else { return }
        generatedCode       = p.productCode
        nombreField.text    = p.productName
        categoriaField.text = p.categoryValue
        selectedCategory    = p.categoryValue
        precioField.text    = String(format: "%.2f", p.priceDouble)
        stockField.text     = "\(p.stockInt)"
        estadoSwitch.isOn   = p.isActive
        updateEstadoLabel()

        if let path = p.productImagePath {
            photoImageView.contentMode = .scaleAspectFill
            photoImageView.setImage(from: path)
            photoImageView.tintColor = nil
        }

        // Sync picker selection
        if let index = categories.firstIndex(of: p.categoryValue) {
            categoryPickerView.selectRow(index, inComponent: 0, animated: false)
        }
    }

    // MARK: - Actions

    @objc private func handleSave() {
        guard validate() else { return }

        let code     = generatedCode
        let name     = nombreField.text?.trimmed ?? ""
        let category = selectedCategory
        let price    = Double(precioField.text?.trimmed ?? "0") ?? 0
        let stock    = Int(stockField.text?.trimmed ?? "0") ?? 0
        let estado   = estadoSwitch.isOn ? "Activo" : "Inactivo"
        let photo    = selectedPhotoPath

        Task {
            do {
                if self.isEditMode, let p = self.producto {
                    try await ProductoService.shared.update(p, code: code, name: name, category: category,
                                                            price: price, stock: stock,
                                                            photoPath: photo ?? p.productImagePath,
                                                            estado: estado)
                } else {
                    try await ProductoService.shared.create(code: code, name: name, category: category,
                                                            price: price, stock: stock,
                                                            photoPath: photo)
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

    @objc private func handleSelectPhoto() {
        showImageSourcePicker { [weak self] in self?.openCamera() }
                              onGallery: { [weak self] in self?.openGallery() }
    }

    private func openCamera() {
        let picker = UIImagePickerController()
        picker.sourceType  = .camera
        picker.delegate    = self
        present(picker, animated: true)
    }

    private func openGallery() {
        var config = PHPickerConfiguration()
        config.filter          = .images
        config.selectionLimit  = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    /// Resize, persist, and preview a picked image. Shared by camera and gallery.
    private func applyPickedImage(_ image: UIImage) {
        let resized   = image.resized(maxDimension: 800)
        let fileName  = "\(UUID().compact).jpg"
        selectedPhotoPath        = resized.saveToDocuments(named: fileName)
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.image       = resized
        photoImageView.tintColor   = nil
    }

    @objc private func categoryPickerDone() {
        categoriaField.resignFirstResponder()
        let row = categoryPickerView.selectedRow(inComponent: 0)
        selectedCategory    = categories[row]
        categoriaField.text = selectedCategory
        if !isEditMode { refreshAutoCode() }
        _ = validate()
    }

    private func refreshAutoCode() {
        Task { if let code = try? await ProductoService.shared.generateCode(for: selectedCategory) { await MainActor.run { self.generatedCode = code } } }
    }

    @objc private func estadoChanged() { updateEstadoLabel() }

    private func updateEstadoLabel() {
        estadoValueLabel.text      = estadoSwitch.isOn ? "Activo" : "Inactivo"
        estadoValueLabel.textColor = estadoSwitch.isOn ? .appSuccess : .appTextSecondary
    }

    @objc private func fieldsChanged() { _ = validate() }
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

        let nombre = nombreField.text?.trimmed ?? ""
        if nombre.isEmpty {
            setError(nombreError, nombreField, "El nombre es requerido.")
            valid = false
        } else { clearError(nombreError, nombreField) }

        if selectedCategory.isEmpty {
            setError(categoriaError, categoriaField, "Selecciona una categoría.")
            valid = false
        } else { clearError(categoriaError, categoriaField) }

        let precioStr = precioField.text?.trimmed ?? ""
        if precioStr.isEmpty {
            setError(precioError, precioField, "El precio es requerido.")
            valid = false
        } else if Decimal(string: precioStr) == nil {
            setError(precioError, precioField, "Ingresa un precio válido.")
            valid = false
        } else if let precio = Decimal(string: precioStr), precio <= 0 {
            setError(precioError, precioField, "El precio debe ser mayor a 0.")
            valid = false
        } else { clearError(precioError, precioField) }

        let stockStr = stockField.text?.trimmed ?? ""
        if stockStr.isEmpty {
            setError(stockError, stockField, "El stock es requerido.")
            valid = false
        } else if let s = Int(stockStr), s < 0 {
            setError(stockError, stockField, "El stock no puede ser negativo.")
            valid = false
        } else if Int(stockStr) == nil {
            setError(stockError, stockField, "Ingresa un stock válido.")
            valid = false
        } else { clearError(stockError, stockField) }

        navigationItem.rightBarButtonItem?.isEnabled = valid
        return valid
    }

    private func setError(_ label: UILabel, _ field: UITextField, _ msg: String) {
        label.text = msg; label.isHidden = false
        AppStyle.markFieldError(field, hasError: true)
    }
    private func clearError(_ label: UILabel, _ field: UITextField) {
        label.isHidden = true
        AppStyle.markFieldError(field, hasError: false)
    }
}

// MARK: - UITextFieldDelegate

extension FormularioProductoViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nombreField:    categoriaField.becomeFirstResponder()
        case categoriaField: precioField.becomeFirstResponder()
        case precioField:    stockField.becomeFirstResponder()
        default:             textField.resignFirstResponder()
        }
        return true
    }

}

// MARK: - UIPickerViewDataSource / Delegate

extension FormularioProductoViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        categories.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        categories[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedCategory    = categories[row]
        categoriaField.text = selectedCategory
    }
}

// MARK: - UIImagePickerControllerDelegate (camera only)

extension FormularioProductoViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage else { return }
        applyPickedImage(image)
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate (gallery)

extension FormularioProductoViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let provider = results.first?.itemProvider,
              provider.canLoadObject(ofClass: UIImage.self) else { return }
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async { self?.applyPickedImage(image) }
        }
    }
}
