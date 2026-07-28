//
//  GameViewController.swift
//  Car game
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    private weak var gameScene: GameScene?

    private var selectedLevel:   GameLevel   = .mountain
    private var selectedVehicle: GameVehicle = .classic

    private var homeOverlay:  UIView!
    private var homeGradient: CAGradientLayer!
    private var gasPedal:     PedalButton!
    private var brkPedal:     PedalButton!
    private var homeButton:   UIButton!
    private var levelCards:   [GameLevel: UIButton]   = [:]
    private var vehicleCards: [GameVehicle: UIButton] = [:]
    private var scoresLabel:  UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let skView = self.view as? SKView else { return }
        skView.ignoresSiblingOrder = true
        // skView.showsPhysics = true  // debug

        setupPedals()
        setupHomeButton()
        buildHomeScreen()
        showHome()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        homeGradient?.frame = view.bounds
    }

    // MARK: - Flow
    private func showHome() {
        (view as? SKView)?.presentScene(nil)
        gameScene = nil
        homeOverlay.isHidden = false
        gasPedal.isHidden = true; brkPedal.isHidden = true; homeButton.isHidden = true
        refreshScoresLabel()
    }

    private func refreshScoresLabel() {
        let entries = HighScoreStore.load()
        if entries.isEmpty {
            scoresLabel.text = "No scores yet"
        } else {
            scoresLabel.text = entries.enumerated().map { i, e in
                let name = e.name.padding(toLength: HighScoreStore.maxNameLength,
                                          withPad: " ", startingAt: 0)
                return "\(i + 1). \(name) \(e.score)"
            }.joined(separator: "\n")
        }
    }

    private func startGame() {
        homeOverlay.isHidden = true
        gasPedal.isHidden = false; brkPedal.isHidden = false; homeButton.isHidden = false
        guard let skView = view as? SKView else { return }
        presentGameScene(in: skView)
    }

    private func presentGameScene(in skView: SKView) {
        let scene = GameScene(size: skView.bounds.size,
                              level: selectedLevel, vehicle: selectedVehicle)
        scene.scaleMode = .resizeFill
        scene.onRestartRequested = { [weak self] in
            guard let self, let skView = self.view as? SKView else { return }
            self.presentGameScene(in: skView)
        }
        scene.onCrashed = { [weak self] score in
            self?.handleCrashScore(score)
        }
        skView.presentScene(scene, transition: .fade(withDuration: 0.3))
        gameScene = scene
    }

    // MARK: - High scores
    private func handleCrashScore(_ score: Int) {
        // Pin the leaderboard to the scene that crashed — if the player
        // restarts before saving their name, it must NOT draw on the new run.
        weak let crashScene = gameScene
        guard HighScoreStore.qualifies(score) else {
            crashScene?.displayHighScores()
            return
        }
        let alert = UIAlertController(
            title: "High Score! 🏆",
            message: "\(score) pts made the top \(HighScoreStore.maxEntries). Enter your name:",
            preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "6 letters max"
            tf.text = HighScoreStore.lastName
            tf.autocapitalizationType = .allCharacters
            tf.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            let name = alert.textFields?.first?.text ?? ""
            HighScoreStore.add(name: name, score: score)
            let saved = String(name.trimmingCharacters(in: .whitespaces).prefix(6)).uppercased()
            crashScene?.displayHighScores(
                highlightName: saved.isEmpty ? "RIDER" : saved, highlightScore: score)
        })
        present(alert, animated: true)
    }

    // MARK: - Home screen
    private func buildHomeScreen() {
        homeOverlay = UIView()
        homeOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(homeOverlay)
        NSLayoutConstraint.activate([
            homeOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            homeOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            homeOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            homeOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        homeGradient = CAGradientLayer()
        homeGradient.colors = [
            UIColor(red: 0.13, green: 0.28, blue: 0.50, alpha: 1).cgColor,
            UIColor(red: 0.38, green: 0.64, blue: 0.86, alpha: 1).cgColor
        ]
        homeOverlay.layer.insertSublayer(homeGradient, at: 0)

        let title = UILabel()
        title.text = "MOTO HILL RIDER"
        title.font = UIFont(name: "AvenirNext-Heavy", size: 34) ?? .boldSystemFont(ofSize: 34)
        title.textColor = .white

        let mountain = card(emoji: "🏔️", name: "Mountain")
        let desert   = card(emoji: "🌵", name: "Desert")
        let water    = card(emoji: "🌊", name: "Water")
        let space    = card(emoji: "🪐", name: "Saturn")
        let jungle   = card(emoji: "🌴", name: "Jungle")
        levelCards = [.mountain: mountain, .desert: desert, .water: water,
                      .space: space, .jungle: jungle]
        for (lvl, btn) in levelCards {
            btn.addAction(UIAction { [weak self] _ in
                self?.selectLevel(lvl) }, for: .touchUpInside)
        }

        let classic = card(emoji: "🏍️", name: "Classic")
        let hover   = card(emoji: "🛸", name: "Hover")
        let jetski  = card(emoji: "🚤", name: "Jetski")
        let buggy   = card(emoji: "🚙", name: "Buggy")
        let fanboat = card(emoji: "🛥️", name: "Fan Boat")
        vehicleCards = [.classic: classic, .hover: hover, .jetski: jetski,
                        .buggy: buggy, .fanboat: fanboat]
        for (veh, btn) in vehicleCards {
            btn.addAction(UIAction { [weak self] _ in
                self?.selectVehicle(veh) }, for: .touchUpInside)
        }

        scoresLabel = UILabel()
        scoresLabel.font = .monospacedSystemFont(ofSize: 14, weight: .bold)
        scoresLabel.textColor = .white
        scoresLabel.numberOfLines = HighScoreStore.maxEntries + 1

        let scoresHeader = UILabel()
        scoresHeader.text = "HIGH SCORES"
        scoresHeader.font = .boldSystemFont(ofSize: 13)
        scoresHeader.textColor = UIColor(white: 1, alpha: 0.7)
        let scoresCol = UIStackView(arrangedSubviews: [scoresHeader, scoresLabel])
        scoresCol.axis = .vertical
        scoresCol.spacing = 10
        scoresCol.alignment = .center

        // Two picker rows stacked, scores alongside — 5 cards per row now
        let pickerRows = UIStackView(arrangedSubviews: [
            section(header: "LEVEL",   cards: [mountain, desert, water, space, jungle]),
            section(header: "VEHICLE", cards: [classic, hover, jetski, buggy, fanboat])
        ])
        pickerRows.axis = .vertical
        pickerRows.spacing = 12
        pickerRows.alignment = .center

        let pickers = UIStackView(arrangedSubviews: [pickerRows, scoresCol])
        pickers.axis = .horizontal
        pickers.spacing = 24
        pickers.alignment = .center

        let start = UIButton(type: .system)
        start.setTitle("START", for: .normal)
        start.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 22) ?? .boldSystemFont(ofSize: 22)
        start.setTitleColor(.white, for: .normal)
        start.backgroundColor = UIColor(red: 0.15, green: 0.72, blue: 0.22, alpha: 1)
        start.layer.cornerRadius = 14
        start.addAction(UIAction { [weak self] _ in self?.startGame() }, for: .touchUpInside)
        NSLayoutConstraint.activate([
            start.widthAnchor.constraint(equalToConstant: 220),
            start.heightAnchor.constraint(equalToConstant: 52)
        ])

        let root = UIStackView(arrangedSubviews: [title, pickers, start])
        root.axis = .vertical
        root.spacing = 14
        root.alignment = .center
        root.translatesAutoresizingMaskIntoConstraints = false
        homeOverlay.addSubview(root)
        NSLayoutConstraint.activate([
            root.centerXAnchor.constraint(equalTo: homeOverlay.centerXAnchor),
            root.centerYAnchor.constraint(equalTo: homeOverlay.centerYAnchor)
        ])

        refreshCards()
    }

    private func section(header: String, cards: [UIButton]) -> UIStackView {
        let label = UILabel()
        label.text = header
        label.font = .boldSystemFont(ofSize: 13)
        label.textColor = UIColor(white: 1, alpha: 0.7)

        let row = UIStackView(arrangedSubviews: cards)
        row.axis = .horizontal
        row.spacing = 10

        let col = UIStackView(arrangedSubviews: [label, row])
        col.axis = .vertical
        col.spacing = 10
        col.alignment = .center
        return col
    }

    private func card(emoji: String, name: String) -> UIButton {
        let b = UIButton(type: .custom)
        b.backgroundColor = UIColor(white: 1, alpha: 0.14)
        b.layer.cornerRadius = 12
        NSLayoutConstraint.activate([
            b.widthAnchor.constraint(equalToConstant: 80),
            b.heightAnchor.constraint(equalToConstant: 70)
        ])

        let e = UILabel()
        e.text = emoji
        e.font = .systemFont(ofSize: 26)
        e.textAlignment = .center

        let n = UILabel()
        n.text = name
        n.font = .boldSystemFont(ofSize: 12)
        n.textColor = .white
        n.textAlignment = .center

        let s = UIStackView(arrangedSubviews: [e, n])
        s.axis = .vertical
        s.spacing = 2
        s.isUserInteractionEnabled = false
        s.translatesAutoresizingMaskIntoConstraints = false
        b.addSubview(s)
        NSLayoutConstraint.activate([
            s.centerXAnchor.constraint(equalTo: b.centerXAnchor),
            s.centerYAnchor.constraint(equalTo: b.centerYAnchor)
        ])
        return b
    }

    private func selectLevel(_ level: GameLevel) {
        selectedLevel = level
        // If the current vehicle doesn't run on this level, switch to one that does
        let allowed = allowedVehicles(for: level)
        if !allowed.contains(selectedVehicle) {
            selectedVehicle = allowed.last ?? .classic   // water → jetski feels right
        }
        refreshCards()
    }

    private func selectVehicle(_ vehicle: GameVehicle) {
        guard allowedVehicles(for: selectedLevel).contains(vehicle) else { return }
        selectedVehicle = vehicle
        refreshCards()
    }

    private func refreshCards() {
        for (lvl, btn) in levelCards {
            btn.layer.borderWidth = lvl == selectedLevel ? 3 : 0
            btn.layer.borderColor = UIColor.white.cgColor
            btn.backgroundColor = UIColor(white: 1, alpha: lvl == selectedLevel ? 0.26 : 0.14)
        }
        let allowed = allowedVehicles(for: selectedLevel)
        for (veh, btn) in vehicleCards {
            let isAllowed = allowed.contains(veh)
            btn.isEnabled = isAllowed
            btn.alpha = isAllowed ? 1.0 : 0.35
            btn.layer.borderWidth = veh == selectedVehicle ? 3 : 0
            btn.layer.borderColor = UIColor.white.cgColor
            btn.backgroundColor = UIColor(white: 1, alpha: veh == selectedVehicle ? 0.26 : 0.14)
        }
    }

    // MARK: - In-game home button
    private func setupHomeButton() {
        homeButton = UIButton(type: .system)
        homeButton.setImage(UIImage(systemName: "house.fill"), for: .normal)
        homeButton.tintColor = .white
        homeButton.backgroundColor = UIColor(white: 0, alpha: 0.35)
        homeButton.layer.cornerRadius = 18
        homeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(homeButton)
        NSLayoutConstraint.activate([
            homeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            homeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            homeButton.widthAnchor.constraint(equalToConstant: 36),
            homeButton.heightAnchor.constraint(equalToConstant: 36)
        ])
        homeButton.addAction(UIAction { [weak self] _ in self?.showHome() }, for: .touchUpInside)
    }

    // MARK: - Pedals
    private func setupPedals() {
        gasPedal = PedalButton(frame: .zero)
        gasPedal.configure(color: UIColor(red: 0.15, green: 0.72, blue: 0.22, alpha: 1))
        gasPedal.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(gasPedal)
        NSLayoutConstraint.activate([
            gasPedal.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            gasPedal.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            gasPedal.widthAnchor.constraint(equalToConstant: 110),
            gasPedal.heightAnchor.constraint(equalToConstant: 110)
        ])
        gasPedal.onPress   = { [weak self] in self?.gameScene?.setGas(true) }
        gasPedal.onRelease = { [weak self] in self?.gameScene?.setGas(false) }

        brkPedal = PedalButton(frame: .zero)
        brkPedal.configure(color: UIColor(red: 0.85, green: 0.18, blue: 0.15, alpha: 1))
        brkPedal.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(brkPedal)
        NSLayoutConstraint.activate([
            brkPedal.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            brkPedal.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            brkPedal.widthAnchor.constraint(equalToConstant: 110),
            brkPedal.heightAnchor.constraint(equalToConstant: 110)
        ])
        brkPedal.onPress   = { [weak self] in self?.gameScene?.setBrake(true) }
        brkPedal.onRelease = { [weak self] in self?.gameScene?.setBrake(false) }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .phone ? .landscape : .all
    }

    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }

    // MARK: - Hardware keyboard (Simulator: I/O ▸ Keyboard ▸ Connect Hardware Keyboard)
    // Space = gas, Shift = brake.
    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponder()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false
        for press in presses {
            switch press.key?.keyCode {
            case .keyboardSpacebar:
                gameScene?.setGas(true);   handled = true
            case .keyboardLeftShift, .keyboardRightShift:
                gameScene?.setBrake(true); handled = true
            default: break
            }
        }
        if !handled { super.pressesBegan(presses, with: event) }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        var handled = false
        for press in presses {
            switch press.key?.keyCode {
            case .keyboardSpacebar:
                gameScene?.setGas(false);   handled = true
            case .keyboardLeftShift, .keyboardRightShift:
                gameScene?.setBrake(false); handled = true
            default: break
            }
        }
        if !handled { super.pressesEnded(presses, with: event) }
    }
}

// MARK: - PedalButton
final class PedalButton: UIView {

    var onPress:   (() -> Void)?
    var onRelease: (() -> Void)?

    private let padView  = UIView()

    func configure(color: UIColor) {
        backgroundColor = .clear
        layer.cornerRadius = 14

        // Outer dark surround
        let bg = UIView()
        bg.backgroundColor    = UIColor(white: 0.12, alpha: 0.85)
        bg.layer.cornerRadius = 16
        bg.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bg)
        NSLayoutConstraint.activate([
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.topAnchor.constraint(equalTo: topAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Coloured pad
        padView.backgroundColor    = color
        padView.layer.cornerRadius = 12
        padView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(padView)
        NSLayoutConstraint.activate([
            padView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            padView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            padView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            padView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])

        // Grip dots on the pad
        let dots = UIView()
        dots.translatesAutoresizingMaskIntoConstraints = false
        padView.addSubview(dots)
        NSLayoutConstraint.activate([
            dots.centerXAnchor.constraint(equalTo: padView.centerXAnchor),
            dots.centerYAnchor.constraint(equalTo: padView.centerYAnchor),
            dots.widthAnchor.constraint(equalToConstant: 44),
            dots.heightAnchor.constraint(equalToConstant: 44)
        ])
        for row in 0..<3 { for col in 0..<3 {
            let d = UIView(frame: CGRect(x: CGFloat(col)*18, y: CGFloat(row)*18, width: 8, height: 8))
            d.backgroundColor    = UIColor(white: 0, alpha: 0.25)
            d.layer.cornerRadius = 4
            dots.addSubview(d)
        }}

        // Touch handling
        let press   = UILongPressGestureRecognizer(target: self, action: #selector(handlePress(_:)))
        press.minimumPressDuration = 0
        addGestureRecognizer(press)
    }

    @objc private func handlePress(_ g: UILongPressGestureRecognizer) {
        switch g.state {
        case .began:
            onPress?()
            UIView.animate(withDuration: 0.08) { self.padView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92) }
        case .ended, .cancelled, .failed:
            onRelease?()
            UIView.animate(withDuration: 0.08) { self.padView.transform = .identity }
        default: break
        }
    }
}
