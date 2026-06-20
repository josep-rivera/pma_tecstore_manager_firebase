import UIKit

final class LoginViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var correoField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!

    private var hasAttemptedSubmit = false

    // MARK: - UI (programmatic — decorative, not IBOutlets)
    private let correoError   = AppStyle.makeErrorLabel()
    private let passwordError = AppStyle.makeErrorLabel()

    private let logoBackground: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor    = UIColor.brandPrimary.withAlphaComponent(0.10)
        v.layer.cornerRadius = 50
        return v
    }()
    private let logoImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "storefront.fill"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.tintColor   = .brandPrimary
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text          = "TecStore Manager"
        l.font          = AppFont.title1()
        l.textColor     = .appTextPrimary
        l.textAlignment = .center
        return l
    }()
    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text          = "Inicia sesión para continuar"
        l.font          = AppFont.body()
        l.textColor     = .appTextSecondary
        l.textAlignment = .center
        return l
    }()

    private let seedCredentialsLabel: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.numberOfLines = 0
        l.textAlignment = .center
        l.font          = AppFont.caption1()
        l.textColor     = .appTextTertiary
        l.text          = "Cuentas de prueba\nana.garcia@tecsup.edu.pe  •  123456\ncarlos.mendoza@tecsup.edu.pe  •  123456"
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
        loginButton.isEnabled = false
        loginButton.alpha = 0.6
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
        AppStyle.style(textField: correoField,
                       placeholder: "Correo electrónico",
                       icon: "envelope",
                       keyboardType: .emailAddress,
                       returnKey: .next)
        correoField.delegate = self
        correoField.addTarget(self, action: #selector(fieldsChanged), for: .editingChanged)

        AppStyle.style(textField: passwordField,
                       placeholder: "Contraseña",
                       icon: "lock",
                       isSecure: true,
                       returnKey: .done)
        passwordField.delegate = self
        passwordField.addTarget(self, action: #selector(fieldsChanged), for: .editingChanged)
    }

    private func setupButtons() {
        AppStyle.applyPrimary(to: loginButton, title: "Iniciar sesión")
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)

        AppStyle.applyText(to: registerButton, title: "Crear una cuenta nueva")
    }

    /// Add error labels and seed credentials to the view hierarchy.
    /// Error labels are placed relative to their IBOutlet fields in the storyboard's contentView.
    private func setupProgrammaticViews() {
        guard let contentView = correoField.superview else { return }
        let ph = AppLayout.paddingLarge

        // Decorative header: logo + title + subtitle above the IBOutlet fields
        logoBackground.addSubview(logoImageView)
        for v in [logoBackground, titleLabel, subtitleLabel] { contentView.addSubview(v) }

        // Error labels below their fields
        for label in [correoError, passwordError] {
            label.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(label)
        }

        // Seed credentials hint at the bottom of the root view
        view.addSubview(seedCredentialsLabel)

        NSLayoutConstraint.activate([
            // Logo circle
            logoBackground.topAnchor.constraint(equalTo: contentView.topAnchor, constant: ph),
            logoBackground.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoBackground.widthAnchor.constraint(equalToConstant: 100),
            logoBackground.heightAnchor.constraint(equalToConstant: 100),

            logoImageView.centerXAnchor.constraint(equalTo: logoBackground.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: logoBackground.centerYAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 48),
            logoImageView.heightAnchor.constraint(equalToConstant: 48),

            // Title
            titleLabel.topAnchor.constraint(equalTo: logoBackground.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),

            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: ph),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -ph),

            // First field below subtitle
            correoField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),

            // Error labels
            correoError.topAnchor.constraint(equalTo: correoField.bottomAnchor, constant: 4),
            correoError.leadingAnchor.constraint(equalTo: correoField.leadingAnchor),
            correoError.trailingAnchor.constraint(equalTo: correoField.trailingAnchor),

            passwordError.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 4),
            passwordError.leadingAnchor.constraint(equalTo: passwordField.leadingAnchor),
            passwordError.trailingAnchor.constraint(equalTo: passwordField.trailingAnchor),

            // Seed hint
            seedCredentialsLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: ph),
            seedCredentialsLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -ph),
            seedCredentialsLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
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

    @objc private func handleLogin() {
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

    @objc private func fieldsChanged()   { _ = validate() }
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
            valid = false
        } else if !correo.isValidEmail {
            if hasAttemptedSubmit { setError(correoError, correoField, "Formato de correo inválido.") }
            valid = false
        } else {
            clearError(correoError, correoField)
        }

        let pwd = passwordField.text ?? ""
        if pwd.isEmpty {
            if hasAttemptedSubmit { setError(passwordError, passwordField, "La contraseña es requerida.") }
            valid = false
        } else if pwd.count < 6 {
            if hasAttemptedSubmit { setError(passwordError, passwordField, "Mínimo 6 caracteres.") }
            valid = false
        } else {
            clearError(passwordError, passwordField)
        }

        loginButton.isEnabled = valid
        loginButton.alpha     = valid ? 1 : 0.6
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
        else { textField.resignFirstResponder(); handleLogin() }
        return true
    }
}
