import UIKit

final class LoginViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var correoField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!

    // Storyboard-placed decorative views
    @IBOutlet weak var logoBackground: UIView!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var seedCredentialsLabel: UILabel!

    // Storyboard-placed error labels (T-03)
    @IBOutlet weak var correoError: UILabel!
    @IBOutlet weak var passwordError: UILabel!

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
        AppStyle.style(textField: correoField,
                       placeholder: "Correo electrónico",
                       icon: "envelope",
                       keyboardType: .emailAddress,
                       returnKey: .next)
        correoField.delegate = self

        AppStyle.style(textField: passwordField,
                       placeholder: "Contraseña",
                       icon: "lock",
                       isSecure: true,
                       returnKey: .done)
        passwordField.delegate = self
    }

    private func setupButtons() {
        AppStyle.applyPrimary(to: loginButton, title: "Iniciar sesión")
        AppStyle.applyText(to: registerButton, title: "Crear una cuenta nueva")
    }

    /// Apply theme colors to storyboard-placed decorative views.
    private func applyThemeColors() {
        logoBackground.backgroundColor    = UIColor.brandPrimary.withAlphaComponent(0.10)
        logoBackground.layer.cornerRadius = 50
        logoImageView.tintColor           = .brandPrimary
        titleLabel.font                   = AppFont.title1()
        titleLabel.textColor              = .appTextPrimary
        subtitleLabel.font                = AppFont.body()
        subtitleLabel.textColor           = .appTextSecondary
        seedCredentialsLabel.font         = AppFont.caption1()
        seedCredentialsLabel.textColor    = .appTextTertiary
        correoError.textColor             = .appError
        correoError.font                  = AppFont.caption1()
        passwordError.textColor           = .appError
        passwordError.font                = AppFont.caption1()
    }

    private func setupKeyboard() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - Actions

    @IBAction @objc private func handleLogin(_ sender: UIButton) {
        hasAttemptedSubmit = true
        guard validate() else { return }
        loginButton.isEnabled = false
        loginButton.alpha     = 0.6
        Task {
            do {
                try await AuthService.shared.login(
                    email:    correoField.text ?? "",
                    password: passwordField.text ?? ""
                )
                (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.switchToMenu()
            } catch let error as ServiceError {
                showAlert(title: "Error al iniciar sesión",
                          message: error.errorDescription ?? "")
                loginButton.isEnabled = true
                loginButton.alpha     = 1
            } catch {
                showAlert(title: "Error", message: error.localizedDescription)
                loginButton.isEnabled = true
                loginButton.alpha     = 1
            }
        }
    }

    @IBAction @objc private func fieldsChanged(_ sender: UITextField) { _ = validate() }
    @objc private func tapToDismiss() { view.endEditing(true) }

    @objc private func keyboardWillShow(_ n: NSNotification) {
        if let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
           let scrollView = view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.contentInset.bottom                    = frame.height + 20
            scrollView.verticalScrollIndicatorInsets.bottom   = frame.height
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

        let correo = correoField.text?.trimmed ?? ""
        if correo.isEmpty {
            if hasAttemptedSubmit { setError(correoError, correoField, "El correo es requerido.") }
            else { clearError(correoError, correoField) }
            valid = false
        } else if !correo.isValidEmail {
            if hasAttemptedSubmit { setError(correoError, correoField, "Formato de correo inválido.") }
            else { clearError(correoError, correoField) }
            valid = false
        } else {
            clearError(correoError, correoField)
        }

        let pwd = passwordField.text ?? ""
        if pwd.isEmpty {
            if hasAttemptedSubmit { setError(passwordError, passwordField, "La contraseña es requerida.") }
            else { clearError(passwordError, passwordField) }
            valid = false
        } else if pwd.count < 6 {
            if hasAttemptedSubmit { setError(passwordError, passwordField, "Mínimo 6 caracteres.") }
            else { clearError(passwordError, passwordField) }
            valid = false
        } else {
            clearError(passwordError, passwordField)
        }
        return valid
    }

    private func setError(_ label: UILabel, _ field: UITextField, _ msg: String) {
        label.text     = msg
        label.isHidden = false
        AppStyle.markFieldError(field, hasError: true)
    }
    private func clearError(_ label: UILabel, _ field: UITextField) {
        label.isHidden = true
        AppStyle.markFieldError(field, hasError: false)
    }
}

// MARK: - UITextFieldDelegate

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == correoField { passwordField.becomeFirstResponder() }
        else { textField.resignFirstResponder(); handleLogin(loginButton) }
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
