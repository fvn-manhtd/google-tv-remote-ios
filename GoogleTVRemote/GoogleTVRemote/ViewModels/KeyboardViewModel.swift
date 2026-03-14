import Foundation
import AndroidTVRemoteControl

@MainActor
class KeyboardViewModel: ObservableObject {
    @Published var text: String = ""

    private let remoteService: TVRemoteService

    init(remoteService: TVRemoteService) {
        self.remoteService = remoteService
    }

    func sendText(_ text: String) {
        let chars = Array(text)
        Task {
            // Dismiss the on-screen keyboard (Gboard) so key events go
            // directly to the focused text field instead of being consumed
            // by the virtual keyboard as navigation input.
            remoteService.sendKey(.KEYCODE_BACK)
            try? await Task.sleep(nanoseconds: 300_000_000)

            for char in chars {
                if let key = keyCode(for: char) {
                    remoteService.sendKey(key)
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
            }
        }
    }

    func sendCharacter(_ char: Character) {
        if let key = keyCode(for: char) {
            remoteService.sendKey(key)
        }
    }

    func sendBackspace() {
        remoteService.sendKey(.KEYCODE_DEL)
    }

    func sendEnter() {
        remoteService.sendKey(.KEYCODE_ENTER)
    }

    private func keyCode(for char: Character) -> Key? {
        let upper = char.uppercased()
        switch upper {
        case "A": return .KEYCODE_A
        case "B": return .KEYCODE_B
        case "C": return .KEYCODE_C
        case "D": return .KEYCODE_D
        case "E": return .KEYCODE_E
        case "F": return .KEYCODE_F
        case "G": return .KEYCODE_G
        case "H": return .KEYCODE_H
        case "I": return .KEYCODE_I
        case "J": return .KEYCODE_J
        case "K": return .KEYCODE_K
        case "L": return .KEYCODE_L
        case "M": return .KEYCODE_M
        case "N": return .KEYCODE_N
        case "O": return .KEYCODE_O
        case "P": return .KEYCODE_P
        case "Q": return .KEYCODE_Q
        case "R": return .KEYCODE_R
        case "S": return .KEYCODE_S
        case "T": return .KEYCODE_T
        case "U": return .KEYCODE_U
        case "V": return .KEYCODE_V
        case "W": return .KEYCODE_W
        case "X": return .KEYCODE_X
        case "Y": return .KEYCODE_Y
        case "Z": return .KEYCODE_Z
        case "0": return .KEYCODE_0
        case "1": return .KEYCODE_1
        case "2": return .KEYCODE_2
        case "3": return .KEYCODE_3
        case "4": return .KEYCODE_4
        case "5": return .KEYCODE_5
        case "6": return .KEYCODE_6
        case "7": return .KEYCODE_7
        case "8": return .KEYCODE_8
        case "9": return .KEYCODE_9
        case " ": return .KEYCODE_SPACE
        case ".": return .KEYCODE_PERIOD
        case ",": return .KEYCODE_COMMA
        case "@": return .KEYCODE_AT
        case "-": return .KEYCODE_MINUS
        case "/": return .KEYCODE_SLASH
        case "+": return .KEYCODE_PLUS
        case "#": return .KEYCODE_POUND
        case "*": return .KEYCODE_STAR
        case "(": return .KEYCODE_NUMPAD_LEFT_PAREN
        case ")": return .KEYCODE_NUMPAD_RIGHT_PAREN
        case "=": return .KEYCODE_EQUALS
        case ";": return .KEYCODE_SEMICOLON
        case "'": return .KEYCODE_APOSTROPHE
        case "\\": return .KEYCODE_BACKSLASH
        case "`": return .KEYCODE_GRAVE
        case "[": return .KEYCODE_LEFT_BRACKET
        case "]": return .KEYCODE_RIGHT_BRACKET
        case "\t": return .KEYCODE_TAB
        default:  return nil
        }
    }
}
