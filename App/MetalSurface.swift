import SwiftUI
import MetalKit

/// Owns only the selected look touch, never joystick, guard, or keyboard state.
struct LookTouchSelection<Touch: AnyObject> {
    var active: Touch?
    mutating func end(_ touches: [Touch]) {
        if let active, touches.contains(where: { $0 === active }) { self.active = nil }
    }
}

private func configure(_ view: MTKView, model: GameModel) -> Renderer? {
    view.device = MTLCreateSystemDefaultDevice()
    view.colorPixelFormat = .bgra8Unorm_srgb
    view.depthStencilPixelFormat = .depth32Float
    view.clearColor = MTLClearColor(red: 0.035, green: 0.065, blue: 0.075, alpha: 1)
    view.preferredFramesPerSecond = 60
    do {
        let renderer = try Renderer(view: view, model: model)
        view.delegate = renderer
        return renderer
    } catch {
        DispatchQueue.main.async { model.rendererError = "Metal could not start: \(error)" }
        return nil
    }
}

#if os(macOS)
struct MetalSurface: NSViewRepresentable {
    let model: GameModel
    func makeNSView(context: Context) -> NativeMetalView {
        let view = NativeMetalView(frame: .zero)
        view.model = model
        view.renderer = configure(view, model: model)
        return view
    }
    func updateNSView(_ view: NativeMetalView, context: Context) {
        if model.started && view.window?.firstResponder !== view { view.window?.makeFirstResponder(view) }
    }
}
final class NativeMetalView: MTKView {
    weak var model: GameModel?
    var renderer: Renderer?
    override var acceptsFirstResponder: Bool { true }
    override func keyDown(with event: NSEvent) { model?.keyDown(event.keyCode, repeating: event.isARepeat) }
    override func keyUp(with event: NSEvent) { model?.keys.remove(event.keyCode) }
    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        if model?.started == true { model?.world.attack() }
    }
    override func mouseDragged(with event: NSEvent) { model?.look(dx: Float(event.deltaX), dy: Float(event.deltaY)) }
    override func rightMouseDown(with event: NSEvent) { model?.touchBlock = true }
    override func rightMouseUp(with event: NSEvent) { model?.touchBlock = false }
    override func resignFirstResponder() -> Bool { model?.clearInput(); return true }
}
#else
struct MetalSurface: UIViewRepresentable {
    let model: GameModel
    func makeUIView(context: Context) -> NativeMetalView {
        let view = NativeMetalView(frame: .zero)
        view.model = model
        view.isMultipleTouchEnabled = true
        view.renderer = configure(view, model: model)
        return view
    }
    func updateUIView(_ view: NativeMetalView, context: Context) {}
}
final class NativeMetalView: MTKView {
    weak var model: GameModel?
    var renderer: Renderer?
    private var look = LookTouchSelection<UITouch>()
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if look.active == nil { look.active = touches.first(where: { $0.location(in: self).x > bounds.width * 0.4 }) }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = look.active, touches.contains(touch) else { return }
        let p = touch.location(in: self), previous = touch.previousLocation(in: self)
        model?.look(dx: Float(p.x - previous.x), dy: Float(p.y - previous.y))
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        look.end(Array(touches))
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        look.end(Array(touches))
    }
}
#endif
