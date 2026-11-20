import SwiftUI

final class GameModel: ObservableObject {
    @Published var world = World()
    @Published var started = false
    @Published var rendererError: String?
    var keys: Set<UInt16> = []
    var touchMove = Vec2()
    var touchBlock = false
    var pitch: Float = -0.06

    func tick(_ dt: Float) {
        guard started else { return }
        let horizontal: Float = (keys.contains(2) ? 1 : 0) - (keys.contains(0) ? 1 : 0)
        let vertical: Float = (keys.contains(13) || keys.contains(126) ? 1 : 0) - (keys.contains(1) || keys.contains(125) ? 1 : 0)
        let turn: Float = (keys.contains(124) ? 1 : 0) - (keys.contains(123) ? 1 : 0)
        let input = Input(move: Vec2(horizontal, vertical) + touchMove, turn: turn * 2.1,
                          blocking: keys.contains(3) || touchBlock)
        world.step(seconds: dt, input: input)
        if keys.contains(49) { world.attack() }
    }
    func begin() { clearInput(); started = true; world.paused = false }
    func restart() { world = World(); pitch = -0.06; begin() }
    func clearInput() { keys.removeAll(); touchMove = Vec2(); touchBlock = false }
    func togglePause() { clearInput(); world.paused.toggle() }
    func look(dx: Float, dy: Float) {
        guard started, !world.paused, !world.isDead else { return }
        world.player.yaw += dx * 0.006
        pitch = min(0.65, max(-0.65, pitch - dy * 0.004))
    }
    func keyDown(_ code: UInt16, repeating: Bool) {
        guard started else { return }
        keys.insert(code)
        guard !repeating else { return }
        switch code {
        case 14: world.interact()
        case 53: togglePause()
        case 15: if world.isDead { restart() }
        default: break
        }
    }
}
