import XCTest
import Foundation
@testable import EmberNative

final class RegressionTests: XCTestCase {
    func testAllocationFailureThenRetryClearsError() {
        var cache = DungeonGeometryCache<String>()
        XCTAssertNil(cache.resolve(floor: 1) { nil })
        XCTAssertNotNil(cache.error)
        let retry = cache.resolve(floor: 1) { ("floor-one", 36) }
        XCTAssertEqual(retry?.resource, "floor-one")
        XCTAssertEqual(retry?.vertexCount, 36)
        XCTAssertNil(cache.error)
    }

    func testFailedFloorTransitionCanRestartUsingLastGoodGeometry() {
        var cache = DungeonGeometryCache<String>()
        _ = cache.resolve(floor: 1) { ("floor-one", 36) }
        XCTAssertNil(cache.resolve(floor: 2) { nil })
        XCTAssertNotNil(cache.error)
        let restarted = cache.resolve(floor: 1) {
            XCTFail("The valid first-floor resource should remain cached")
            return nil
        }
        XCTAssertEqual(restarted?.resource, "floor-one")
        XCTAssertEqual(restarted?.vertexCount, 36)
        XCTAssertNil(cache.error)
        let next = cache.resolve(floor: 2) { ("floor-two", 72) }
        XCTAssertEqual(next?.resource, "floor-two")
        XCTAssertEqual(next?.vertexCount, 72)
        XCTAssertNil(cache.error)
    }

    func testCancelOnlySelectedLookPreservesMovementGuardAndOtherTouches() {
        let model = GameModel()
        model.begin()
        model.touchMove = Vec2(0, 1)
        model.touchBlock = true
        let selected = NSObject(), unrelated = NSObject()
        var look = LookTouchSelection<NSObject>()
        look.active = selected
        look.end([unrelated])
        XCTAssertTrue(look.active === selected)
        look.end([selected])
        XCTAssertNil(look.active)
        let before = model.world.player.position
        model.tick(0.01)
        XCTAssertEqual(model.touchMove, Vec2(0, 1))
        XCTAssertTrue(model.world.blocking)
        XCTAssertGreaterThan((model.world.player.position - before).length, 0)
        // Pause and focus loss must still clear all input through the existing path.
        model.togglePause()
        XCTAssertEqual(model.touchMove, Vec2())
        XCTAssertFalse(model.touchBlock)
    }

    func testGateFrameAndSealFollowExitWithoutChangingGeometry() {
        let origin = Dungeon(seed: 42).exit.center
        let offset = Vec2(2, 3)
        let pairs = [
            (Mesh.gateFrame(at: origin), Mesh.gateFrame(at: origin + offset)),
            (Mesh.gateSeal(at: origin, open: false), Mesh.gateSeal(at: origin + offset, open: false)),
            (Mesh.gateSeal(at: origin, open: true), Mesh.gateSeal(at: origin + offset, open: true))
        ]
        for (original, shifted) in pairs {
            XCTAssertFalse(original.vertices.isEmpty)
            XCTAssertEqual(original.vertices.count, shifted.vertices.count)
            for (a, b) in zip(original.vertices, shifted.vertices) {
                XCTAssertEqual(b.position.x - a.position.x, offset.x, accuracy: 0.00001)
                XCTAssertEqual(b.position.y, a.position.y, accuracy: 0.00001)
                XCTAssertEqual(b.position.z - a.position.z, offset.y, accuracy: 0.00001)
                XCTAssertEqual(a.color, b.color)
            }
        }
    }
}
