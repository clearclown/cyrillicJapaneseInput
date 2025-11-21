//
//  KeyboardViewController.swift
//  CyrillicKeyboard
//
//  Main keyboard extension view controller (Refactored for Phase 1)
//

import UIKit

class KeyboardViewController: UIInputViewController {
    // MARK: - Managers

    /// Manages text display using iOS IME protocols
    private var displayedTextManager: DisplayedTextManager!

    /// Manages Cyrillic input and conversion
    private var inputManager: CyrillicInputManager!

    /// Kanji conversion engine (Phase 2)
    private var conversionEngine: KanjiConversionEngine?

    // MARK: - UI Components

    /// Keyboard view
    private var keyboardView: CyrillicKeyboardView?

    /// Initialization error message (for debugging)
    private var initializationError: String?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        print("[KeyboardViewController] viewDidLoad started")

        // Initialize engine and profiles
        initializeEngine()

        // Setup managers
        setupManagers()

        // Setup keyboard view
        setupKeyboardView()

        // Subscribe to profile changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProfileChanged),
            name: .profileDidChange,
            object: nil
        )

        print("[KeyboardViewController] viewDidLoad completed")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Update keyboard layout for current profile
        updateKeyboardLayout()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Engine Initialization

    private func initializeEngine() {
        // Initialize ProfileManager
        if let error = ProfileManager.shared.initialize() {
            print("[KeyboardViewController] Initialization error: \(error)")
            initializationError = error
            return
        }

        // Load current schema
        if let error = ProfileManager.shared.loadCurrentSchema() {
            print("[KeyboardViewController] Schema load error: \(error)")
            initializationError = error
            return
        }

        print("[KeyboardViewController] Engine initialized successfully")
        print("[KeyboardViewController] Rust Core version: \(RustCoreFFI.shared.getVersion())")
    }

    // MARK: - Manager Setup

    private func setupManagers() {
        // Phase 2: Initialize conversion engine
        do {
            conversionEngine = try KanjiConversionEngine()
            print("[KeyboardViewController] Kanji conversion engine initialized")
        } catch {
            print("[KeyboardViewController] Failed to initialize conversion engine: \(error)")
            conversionEngine = nil
        }

        // Create DisplayedTextManager
        displayedTextManager = DisplayedTextManager(isMarkedTextEnabled: true)
        displayedTextManager.setTextDocumentProxy(textDocumentProxy)

        // Create CyrillicInputManager (Phase 2: pass conversionEngine)
        inputManager = CyrillicInputManager(
            displayedTextManager: displayedTextManager,
            rustCore: RustCoreFFI.shared,
            profileManager: ProfileManager.shared,
            conversionEngine: conversionEngine
        )

        // Setup callbacks
        inputManager.onCandidatesUpdated = { [weak self] candidates in
            self?.keyboardView?.showCandidates(candidates)
        }

        inputManager.onComposingTextChanged = { [weak self] text in
            self?.keyboardView?.updateBufferDisplay(text)
        }

        print("[KeyboardViewController] Managers initialized")
    }

    // MARK: - Keyboard View Setup

    private func setupKeyboardView() {
        // Show error view if initialization failed
        if let error = initializationError {
            showErrorView(message: error)
            return
        }

        guard let profile = ProfileManager.shared.currentProfile else {
            showErrorView(message: "No profile selected")
            return
        }

        // Create keyboard view
        let keyboard = CyrillicKeyboardView(profile: profile)
        keyboard.delegate = self
        keyboard.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(keyboard)

        NSLayoutConstraint.activate([
            keyboard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboard.topAnchor.constraint(equalTo: view.topAnchor),
            keyboard.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        keyboardView = keyboard

        print("[KeyboardViewController] Keyboard view setup completed")
    }

    private func showErrorView(message: String) {
        let label = UILabel()
        label.text = "Error: \(message)"
        label.textColor = .systemRed
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Profile Management

    @objc private func handleProfileChanged(_ notification: Notification) {
        guard let newProfile = notification.object as? Profile else { return }

        print("[KeyboardViewController] Profile changed to: \(newProfile.id)")

        // Load schema for new profile
        if let error = ProfileManager.shared.loadSchemaForProfile(newProfile) {
            print("[KeyboardViewController] Failed to load schema: \(error)")
            return
        }

        // Update keyboard layout
        updateKeyboardLayout()
    }

    private func updateKeyboardLayout() {
        guard let profile = ProfileManager.shared.currentProfile else { return }
        keyboardView?.updateLayout(for: profile)
    }
}

// MARK: - CyrillicKeyboardViewDelegate

extension KeyboardViewController: CyrillicKeyboardViewDelegate {
    /// Cyrillic key pressed
    func keyboardView(_ view: CyrillicKeyboardView, didPressCyrillicKey key: String) {
        // Handle mode-specific logic
        if view.currentMode != .cyrillic {
            // Numbers/symbols mode: insert directly
            inputManager.commitIfNeeded()
            textDocumentProxy.insertText(key)
            return
        }

        // Update input mode in manager
        inputManager.setInputMode(view.currentInputMode)

        // Process key through manager
        inputManager.processKey(key)
    }

    /// Delete key pressed
    func keyboardViewDidPressDelete(_ view: CyrillicKeyboardView) {
        inputManager.processDelete()
    }

    /// Return key pressed
    func keyboardViewDidPressReturn(_ view: CyrillicKeyboardView) {
        inputManager.processReturn()
        textDocumentProxy.insertText("\n")
    }

    /// Space key pressed
    func keyboardViewDidPressSpace(_ view: CyrillicKeyboardView) {
        inputManager.processSpace()
    }

    /// Globe (keyboard switcher) key pressed
    func keyboardViewDidPressGlobe(_ view: CyrillicKeyboardView) {
        advanceToNextInputMode()
    }

    /// Candidate selected
    func keyboardView(_ view: CyrillicKeyboardView, didSelectCandidate candidate: String) {
        // Find index of selected candidate
        // For now, just commit it (proper index tracking in Phase 2)
        inputManager.commitIfNeeded()
        textDocumentProxy.insertText(candidate)
    }
}
