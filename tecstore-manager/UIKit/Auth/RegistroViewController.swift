import UIKit

final class RegistroViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var nombreField: UITextField!
    @IBOutlet weak var correoField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!

    // MARK: - UI (programmatic — not IBOutlets)
    private let nombreError   = AppStyle.makeErrorLabel()
    private let correoError   = AppStyle.makeErrorLabel()
    private let passwordError = AppStyle.makeErrorLabel()
    private let confirmError  = AppStyle.makeErrorLabel()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text          = "Crear cuenta"
        l.font          = AppFont.title1()
        l.textColor     = .appTextPrimary
        l.textAlignment = .center
        return l
    }()
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text          = "Completa los datos para registrarte"
        l.font          = AppFont.body()
        l.textColor     = .appTextSecondary
        l.textAlignment = .center
        return l
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupFields()
        setupButtons()
        setupProgrammaticViews()
        setupKeyboard()
        _ = validate()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .appBackground
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapToDismiss))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    private func setupFields() {
        let fields: [(UITextField, String, String, UIKeyboardType, UIReturnKeyType, Bool)] = [
            (nombreField,   "Nombre completo",       "person",   .default,      .next, false),
            (correoField,   "Correo electrónico",    "envelope", .emailAddress, .next, false),
            (passwordField, "Contraseña",            "lock",     .default,      .next, true),
            (confirmField,  "Confirmar contraseña",  "lock.fill",.default,      .done, true)
        ]
        for (field, ph, icon, keyboard, returnKey, secure) in fields {
            AppStyle.style(textField: field, placeholder: ph, icon: icon,
                           isSecure: secure, keyboardType: keyboard, returnKey: returnKey)
            field.delegate = self
            field.addTarget(self, action: #selector(fieldsChanged), for: .editingChanged)
        }
        nombreField.autocapitalizationType = .words
    }

    private func setupButtons() {
        AppStyle.applyPrimary(to: registerButton, title: "Crear cuenta")
        registerButton.addTarget(self, action: #selector(handleRegister), for: .touchUpInside)

        AppStyle.applyText(to: loginButton, title: "¿Ya tienes cuenta? Inicia sesión")
        loginButton.addTarget(self, action: #selector(handleGoToLogin), for: .touchUpInside)
    }

    /// Add error labels to the storyboard's contentView.
    /// `nombreField.superview` is the storyboard-provided contentView inside the scrollView.
    private func setupProgrammaticViews() {
        guard let contentView = nombreField.superview else { return }
        let ph = AppLayout.paddingLarge

        for v in [titleLabel, subtitleLabel] { contentView.addSubview(v) }
        for label in [nombreError, correoError, passwordError, confirmError] {
            label.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(label)
        }

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ph),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),

            nombreField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),

            nombreError.topAnchor.constraint(equalTo: nombreField.bottomAnchor, constant: 4),
            nombreError.leadingAnchor.constraint(equalTo: nombreField.leadingAnchor),
            nombreError.trailingAnchor.constraint(equalTo: nombreField.trailingAnchor),

            correoError.topAnchor.constraint(equalTo: correoField.bottomAnchor, constant: 4),
            correoError.leadingAnchor.constraint(equalTo: correoField.leadingAnchor),
            correoError.trailingAnchor.constraint(equalTo: correoField.trailingAnchor),

            passwordError.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 4),
            passwordError.leadingAnchor.constraint(equalTo: passwordField.leadingAnchor),
            passwordError.trailingAnchor.constraint(equalTo: passwordField.trailingAnchor),

            confirmError.topAnchor.constraint(equalTo: confirmField.bottomAnchor, constant: 4),
            confirmError.leadingAnchor.constraint(equalTo: confirmField.leadingAnchor),
            confirmError.trailingAnchor.constraint(equalTo: confirmField.trailingAnchor),
        ])
    }

    private func setupKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Actions

    @objc private func handleRegister() {
        guard validate() else { return }
        do {
            try AuthService.shared.register(
                fullName: nombreField.text ?? "",
                email:    correoField.text ?? "",
                password: passwordField.text ?? ""
            )
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.switchToMenu()
        } catch let error as ServiceError {
            showAlert(title: "Error al registrarse",
                      message: error.errorDescription ?? "")
        } catch {
            showAlert(title: "Error", message: error.localizedDescription)
        }
    }

    @objc private func handleGoToLogin() {
        navigationController?.popViewController(animated: true)
    }
    @objc private func fieldsChanged()   { _ = validate() }
    @objc private func tapToDismiss() { view.endEditing(true) }

    @objc private func keyboardWillShow(_ n: NSNotification) {
        if let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
           let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.contentInset.bottom                  = frame.height + 20
            scrollView.verticalScrollIndicatorInsets.bottom = frame.height
        }
    }
    @objc private func keyboardWillHide(_ n: NSNotification) {
        if let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.contentInset.bottom                  = 0
            scrollView.verticalScrollIndicatorInsets.bottom = 0
        }
    }

    // MARK: - Validation

    @discardableResult
    private func validate() -> Bool {
        var valid = true

        // Nombre
        let nombre = nombreField.text?.trimmed ?? ""
        if nombre.isEmpty {
            setError(nombreError, nombreField, "El nombre es requerido.")
            valid = false
        } else if nombre.count < 3 {
            setError(nombreError, nombreField, "Ingresa tu nombre completo.")
            valid = false
        } else { clearError(nombreError, nombreField) }

        // Correo
        let correo = correoField.text?.trimmed ?? ""
        if correo.isEmpty {
            setError(correoError, correoField, "El correo es requerido.")
            valid = false
        } else if !correo.isValidEmail {
            setError(correoError, correoField, "Formato de correo inválido.")
            valid = false
        } else { clearError(correoError, correoField) }

        // Contraseña
        let pwd = passwordField.text ?? ""
        if pwd.isEmpty {
            setError(passwordError, passwordField, "La contraseña es requerida.")
            valid = false
        } else if pwd.count < 6 {
            setError(passwordError, passwordField, "Mínimo 6 caracteres.")
            valid = false
        } else { clearError(passwordError, passwordField) }

        // Confirmar
        let confirm = confirmField.text ?? ""
        if confirm.isEmpty {
            setError(confirmError, confirmField, "Confirma tu contraseña.")
            valid = false
        } else if confirm != pwd {
            setError(confirmError, confirmField, "Las contraseñas no coinciden.")
            valid = false
        } else { clearError(confirmError, confirmField) }

        registerButton.isEnabled = valid
        registerButton.alpha     = valid ? 1 : 0.6
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

extension RegistroViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case nombreField:   correoField.becomeFirstResponder()
        case correoField:   passwordField.becomeFirstResponder()
        case passwordField: confirmField.becomeFirstResponder()
        default:            textField.resignFirstResponder(); handleRegister()
        }
        return true
    }
}
