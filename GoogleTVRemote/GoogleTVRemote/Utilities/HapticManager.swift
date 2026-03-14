import UIKit

class HapticManager {
    static let shared = HapticManager()

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)

    private init() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
    }

    func light()  { lightGenerator.impactOccurred() }
    func medium() { mediumGenerator.impactOccurred() }
    func heavy()  { heavyGenerator.impactOccurred() }
}
