import MetalKit
import simd

struct Uniforms {
    var viewProjection: simd_float4x4
    var eye: SIMD4<Float>
    var time: SIMD4<Float>
}

enum RenderFailure: Error { case metalUnavailable, missingShaders, bufferAllocation }

/// Commits a resource and its identity together; failed replacements never erase a good entry.
struct DungeonGeometryCache<Resource> {
    struct Entry {
        let floor: Int
        let resource: Resource
        let vertexCount: Int
    }
    private var entry: Entry?
    private(set) var error: String?

    mutating func resolve(floor: Int, build: () -> (Resource, Int)?) -> Entry? {
        if let entry, entry.floor == floor {
            error = nil
            return entry
        }
        guard let (resource, count) = build() else {
            error = "Unable to allocate dungeon geometry."
            return nil
        }
        let replacement = Entry(floor: floor, resource: resource, vertexCount: count)
        entry = replacement
        error = nil
        return replacement
    }
}

final class Renderer: NSObject, MTKViewDelegate {
    let model: GameModel
    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState
    private let depth: MTLDepthStencilState
    private var geometry = DungeonGeometryCache<MTLBuffer>()
    private var lastTime = CACurrentMediaTime()

    init(view: MTKView, model: GameModel) throws {
        guard let device = view.device, let queue = device.makeCommandQueue() else { throw RenderFailure.metalUnavailable }
        guard let url = Bundle.main.url(forResource: "Shaders", withExtension: "metal") else { throw RenderFailure.missingShaders }
        // Runtime compilation avoids requiring Xcode's separately installed Metal compiler.
        let source = try String(contentsOf: url, encoding: .utf8)
        let library = try device.makeLibrary(source: source, options: nil)
        guard let vertex = library.makeFunction(name: "dungeonVertex"),
              let fragment = library.makeFunction(name: "dungeonFragment") else { throw RenderFailure.missingShaders }
        self.device = device
        self.queue = queue
        self.model = model
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertex
        descriptor.fragmentFunction = fragment
        descriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        descriptor.depthAttachmentPixelFormat = .depth32Float
        pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        guard let state = device.makeDepthStencilState(descriptor: depthDescriptor) else { throw RenderFailure.metalUnavailable }
        depth = state
        super.init()
    }
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        let now = CACurrentMediaTime()
        let dt = Float(now - lastTime)
        lastTime = now
        model.tick(dt)
        let world = model.world
        let cached = geometry.resolve(floor: world.floor) {
            let mesh = Mesh.dungeon(world.dungeon)
            guard let buffer = mesh.vertices.withUnsafeBytes({ device.makeBuffer(bytes: $0.baseAddress!, length: $0.count) }) else { return nil }
            return (buffer, mesh.vertices.count)
        }
        // The error follows the same state as the cache, including recovery and restart.
        if model.rendererError != geometry.error { model.rendererError = geometry.error }
        guard let cached else { return }
        guard view.drawableSize.width > 0, view.drawableSize.height > 0,
              let pass = view.currentRenderPassDescriptor, let drawable = view.currentDrawable,
              let command = queue.makeCommandBuffer(), let encoder = command.makeRenderCommandEncoder(descriptor: pass) else { return }
        let eye = SIMD3<Float>(world.player.position.x,1.18,world.player.position.y)
        let direction = SIMD3<Float>(sin(world.player.yaw),model.pitch,-cos(world.player.yaw))
        let aspect = Float(view.drawableSize.width / view.drawableSize.height)
        var uniforms = Uniforms(viewProjection: perspective(aspect: aspect) * lookAt(eye: eye, direction: direction),
                                eye: SIMD4(eye,1), time: SIMD4(world.elapsed,0,0,0))
        encoder.setRenderPipelineState(pipeline)
        encoder.setDepthStencilState(depth)
        encoder.setCullMode(.none)
        encoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 1)
        encoder.setVertexBuffer(cached.resource, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: cached.vertexCount)
        let actors = Mesh.actors(world)
        if let buffer = actors.vertices.withUnsafeBytes({ device.makeBuffer(bytes: $0.baseAddress!, length: $0.count) }) {
            encoder.setVertexBuffer(buffer, offset: 0, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: actors.vertices.count)
        }
        encoder.endEncoding()
        command.present(drawable)
        command.commit()
    }
}

private func perspective(aspect: Float) -> simd_float4x4 {
    let y: Float = 1 / tan(67 * .pi / 360)
    let near: Float = 0.05, far: Float = 35
    let z = far / (near - far)
    return simd_float4x4(SIMD4(y / aspect,0,0,0), SIMD4(0,y,0,0), SIMD4(0,0,z,-1), SIMD4(0,0,z * near,0))
}
private func lookAt(eye: SIMD3<Float>, direction: SIMD3<Float>) -> simd_float4x4 {
    let z = -simd_normalize(direction)
    let x = simd_normalize(simd_cross(SIMD3(0,1,0),z))
    let y = simd_cross(z,x)
    return simd_float4x4(SIMD4(x.x,y.x,z.x,0), SIMD4(x.y,y.y,z.y,0), SIMD4(x.z,y.z,z.z,0),
                        SIMD4(-simd_dot(x,eye),-simd_dot(y,eye),-simd_dot(z,eye),1))
}
