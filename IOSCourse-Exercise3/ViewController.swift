import UIKit

final class ViewController: UIViewController, UITextFieldDelegate {
    private enum Availability { case restoring, emptyOffline, readyOffline, error }

    @IBOutlet private weak var whatMultiply: UITextField!
    @IBOutlet private weak var addButton: UIButton!
    @IBOutlet private weak var multiples: UIButton!
    @IBOutlet private weak var playButton: UIButton!
    @IBOutlet private weak var pressAddToAdd: UILabel!

    private let store = MultiplesSessionStore()
    private var game = MultiplesGame()

    override func viewDidLoad() {
        super.viewDidLoad()
        applyAvailability(.restoring)
        applyTestLaunchStateIfRequested()
        if let restored = store.restore() { game = MultiplesGame(session: restored) }
        whatMultiply.delegate = self
        whatMultiply.keyboardType = .numberPad
        whatMultiply.accessibilityLabel = NSLocalizedString("input.label", comment: "Multiplier input")
        whatMultiply.accessibilityHint = NSLocalizedString("input.hint", comment: "Multiplier rules")
        whatMultiply.accessibilityIdentifier = "multiples.input"
        playButton.accessibilityLabel = NSLocalizedString("button.start", comment: "Start")
        playButton.accessibilityIdentifier = "multiples.start"
        addButton.accessibilityLabel = NSLocalizedString("button.add", comment: "Add")
        addButton.accessibilityIdentifier = "multiples.add"
        multiples.isUserInteractionEnabled = false
        multiples.accessibilityLabel = NSLocalizedString("app.title", comment: "App title")
        multiples.accessibilityTraits = .header
        pressAddToAdd.isAccessibilityElement = true
        pressAddToAdd.accessibilityLabel = NSLocalizedString("status.label", comment: "Status")
        pressAddToAdd.accessibilityIdentifier = "multiples.status"
        pressAddToAdd.adjustsFontForContentSizeCategory = true
        pressAddToAdd.adjustsFontSizeToFitWidth = true
        render()
        NotificationCenter.default.addObserver(self, selector: #selector(saveState), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    @IBAction private func onClickPlayButton(_ sender: AnyObject) {
        view.endEditing(true)
        if game.start(input: whatMultiply.text ?? "") { saveState() }
        render()
    }

    @IBAction private func onClickAddButton(_ sender: AnyObject) {
        _ = game.add()
        saveState()
        render()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    private func render() {
        if let error = game.session.error {
            pressAddToAdd.text = NSLocalizedString("error.\(error.rawValue)", comment: "Validation error")
            applyAvailability(.error)
            announceStatus()
            return
        }
        switch game.session.phase {
        case .configuring:
            whatMultiply.isHidden = false; playButton.isHidden = false
            multiples.isHidden = false; addButton.isHidden = true
            pressAddToAdd.text = NSLocalizedString("status.empty", comment: "Empty state")
            applyAvailability(.emptyOffline)
        case .playing:
            whatMultiply.isHidden = true; playButton.isHidden = true
            multiples.isHidden = true; addButton.isHidden = false
            pressAddToAdd.text = String(format: NSLocalizedString("status.progress", comment: "Progress"), game.session.sum, game.session.multiplier ?? 0, game.session.additions)
            applyAvailability(.readyOffline)
        case .completed:
            whatMultiply.isHidden = false; playButton.isHidden = false
            multiples.isHidden = false; addButton.isHidden = true
            pressAddToAdd.text = String(format: NSLocalizedString("status.completed", comment: "Completed"), game.session.sum)
            game.reset(); store.clear()
            applyAvailability(.readyOffline)
        }
        pressAddToAdd.accessibilityValue = pressAddToAdd.text
    }

    private func announceStatus() {
        pressAddToAdd.accessibilityValue = pressAddToAdd.text
        UIAccessibility.post(notification: .announcement, argument: pressAddToAdd.text)
    }

    private func applyAvailability(_ availability: Availability) {
        switch availability {
        case .restoring: view.accessibilityIdentifier = "multiples.restoring"
        case .emptyOffline: view.accessibilityIdentifier = "multiples.empty.offline"
        case .readyOffline: view.accessibilityIdentifier = "multiples.ready.offline"
        case .error: view.accessibilityIdentifier = "multiples.error"
        }
    }

    private func applyTestLaunchStateIfRequested() {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-reset-multiples-state") { store.clear() }
        if arguments.contains("-inject-malformed-multiples-state") {
            UserDefaults.standard.set(Data("malformed".utf8), forKey: "multiples.session.v1")
        }
    }

    @objc private func saveState() { try? store.save(game.session) }
}
