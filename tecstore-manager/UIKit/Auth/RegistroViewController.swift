import UIKit

final class RegistroViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var nombreField: UITextField!
    @IBOutlet weak var correoField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!

    // Storyboard-placed decorative views
    @IBOutlet weak var logoBackground: UIView!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    // Storyboard-placed error labels (T-05)
    @IBOutlet weak var nombreError: UILabel!
    @IBOutlet weak var correoError: UILabel!
    @IBOutlet weak var passwordError: UILabel!
    @IBOutlet weak var confirmError: UILabel!

    private var hasAttemptedSubmit = false
    private var savedSecure: [UITextField: String] = [:]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupFields()
        setupButtons()
        applyThemeColors()
        setupKeyboard()
        // button always enabled — errors show only after first submit
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        navigationController?.navigationBar.standardAppearance   = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .brandPrimary
        navigationController?.setNavigationBarHidden(false, animated: animated)
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
        }
        nombreField.autocapitalizationType = .words
    }

    private func setupButtons() {
        AppStyle.applyPrimary(to: registerButton, title: "Crear cuenta")
        AppStyle.applyText(to: loginButton, title: "Ya tengo una cuenta")
    }

    /// Apply theme colors to storyboard-placed decorative views.
    private func applyThemeColors() {
        logoBackground.backgroundColor    = UIColor.brandPrimary.withAlphaComponent(0.10)
        logoBackground.layer.cornerRadius = 50
        logoImageView.tintColor           = .brandPrimary
        titleLabel.font          = AppFont.title1()
        titleLabel.textColor     = .appTextPrimary
        subtitleLabel.font       = AppFont.body()
        subtitleLabel.textColor  = .appTextSecondary
        for label in [nombreError, correoError, passwordError, confirmError] {
            label?.textColor = .appError
            label?.font      = AppFont.caption1()
        }
    }

    private func setupKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Actions

    @IBAction @objc private func handleRegister(_ sender: UIButton) {
        hasAttemptedSubmit = true
        guard validate() else { return }
        Task {
            do {
                try await AuthService.shared.register(
                    fullName: nombreField.text ?? "",
                    email:    correoField.text ?? "",
                    password: passwordField.text ?? ""
                )
                await MainActor.run {
                    (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.switchToMenu()
                }
            } catch let error as ServiceError {
                await MainActor.run { self.showAlert(title: "Error al registrarse", message: error.errorDescription ?? "") }
            } catch {
                await MainActor.run { self.showAlert(title: "Error", message: error.localizedDescription) }
            }
        }
    }

    @IBAction @objc private func handleGoToLogin(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }

    @IBAction @objc private func fieldsChanged(_ sender: UITextField) { _ = validate() }
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
            if hasAttemptedSubmit { setError(nombreError, nombreField, "El nombre es requerido.") }
            else { clearError(nombreError, nombreField) }
            valid = false
        } else if nombre.count < 3 {
            if hasAttemptedSubmit { setError(nombreError, nombreField, "Ingresa tu nombre completo.") }
            else { clearError(nombreError, nombreField) }
            valid = false
        } else { clearError(nombreError, nombreField) }

        // Correo
        let correo = correoField.text?.trimmed ?? ""
        if correo.isEmpty {
            if hasAttemptedSubmit { setError(correoError, correoField, "El correo es requerido.") }
            else { clearError(correoError, correoField) }
            valid = false
        } else if !correo.isValidEmail {
            if hasAttemptedSubmit { setError(correoError, correoField, "Formato de correo inválido.") }
            else { clearError(correoError, correoField) }
            valid = false
        } else { clearError(correoError, correoField) }

        // Contraseña
        let pwd = passwordField.text ?? ""
        if pwd.isEmpty {
            if hasAttemptedSubmit { setError(passwordError, passwordField, "La contraseña es requerida.") }
            else { clearError(passwordError, passwordField) }
            valid = false
        } else if pwd.count < 6 {
            if hasAttemptedSubmit { setError(passwordError, passwordField, "Mínimo 6 caracteres.") }
            else { clearError(passwordError, passwordField) }
            valid = false
        } else { clearError(passwordError, passwordField) }

        // Confirmar
        let confirm = confirmField.text ?? ""
        if confirm.isEmpty {
            if hasAttemptedSubmit { setError(confirmError, confirmField, "Confirma tu contraseña.") }
            else { clearError(confirmError, confirmField) }
            valid = false
        } else if confirm != pwd {
            if hasAttemptedSubmit { setError(confirmError, confirmField, "Las contraseñas no coinciden.") }
            else { clearError(confirmError, confirmField) }
            valid = false
        } else { clearError(confirmError, confirmField) }
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
        default:            textField.resignFirstResponder(); handleRegister(registerButton)
        }
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.isSecureTextEntry { savedSecure[textField] = textField.text }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        guard textField.isSecureTextEntry,
              let saved = savedSecure[textField], !saved.isEmpty,
              (textField.text ?? "").isEmpty else { return }
        textField.text = saved
    }
}
