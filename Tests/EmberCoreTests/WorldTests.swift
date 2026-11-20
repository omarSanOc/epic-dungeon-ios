import XCTest
@testable import EmberCore

final class WorldTests: XCTestCase {
    func testDungeonIsDeterministicAndEveryFloorTileIsReachable() {
        let a = Dungeon(seed: 42)
        let b = Dungeon(seed: 42)
        XCTAssertEqual(a.tiles, b.tiles)
        XCTAssertEqual(a.reachableTiles(from: a.start).count, a.tiles.filter { !$0 }.count)
        XCTAssertFalse(a.isWall(a.exit.x, a.exit.y))
        XCTAssertNotEqual(a.start, a.exit)
    }

    func testWallsStopPlayerAndDiagonalSpeedIsNormalized() {
        var world = World(seed: 42)
        world.enemies = []
        let before = world.player.position
        for _ in 0..<120 { world.step(seconds: 1.0 / 60, input: Input(move: Vec2(-1, 0))) }
        XCTAssertTrue(world.dungeon.canStand(at: world.player.position))
        XCTAssertGreaterThanOrEqual(world.player.position.x, 1.2)
        var straight = World(seed: 42)
        var diagonal = straight
        straight.enemies = []; diagonal.enemies = []
        straight.player.position = before
        diagonal.player.position = before
        straight.step(seconds: 0.01, input: Input(move: Vec2(0, 1)))
        diagonal.step(seconds: 0.01, input: Input(move: Vec2(1, 1)))
        XCTAssertEqual((straight.player.position - before).length,
                       (diagonal.player.position - before).length, accuracy: 0.0001)
    }

    func testAttackRequiresFacingAndGrantsLootOnce() {
        var world = World(seed: 42)
        let p = world.player.position
        world.enemies = [Enemy(id: 0, position: p + Vec2(0, -0.8), health: 30)]
        world.attack()
        XCTAssertEqual(world.enemies[0].health, 0)
        XCTAssertEqual(world.gold, 10)
        XCTAssertEqual(world.kills, 1)
        world.attack()
        XCTAssertEqual(world.gold, 10)
        world.enemies = [Enemy(id: 1, position: p + Vec2(0, 0.8), health: 60)]
        world.player.attackCooldown = 0
        world.attack()
        XCTAssertEqual(world.enemies[0].health, 60)
    }

    func testPlayerAttackCooldownProtectsALivingTarget() {
        var world = World(seed: 42)
        world.enemies = [Enemy(id: 0, position: world.player.position + Vec2(0, -0.8), health: 90)]
        world.attack()
        XCTAssertEqual(world.enemies[0].health, 60)
        world.attack()
        XCTAssertEqual(world.enemies[0].health, 60)
        XCTAssertEqual(world.gold, 0)
        for _ in 0..<10 { world.step(seconds: 0.05, input: Input()) }
        world.attack()
        XCTAssertEqual(world.enemies[0].health, 30)
        XCTAssertEqual(world.kills, 0)
    }

    func testPlayerAttackCannotReachDistantVisibleEnemy() {
        var world = World(seed: 42)
        let target = world.player.position + Vec2(0, -2.4)
        XCTAssertTrue(world.dungeon.hasLineOfSight(from: world.player.position, to: target))
        world.enemies = [Enemy(id: 0, position: target, health: 60)]
        world.attack()
        XCTAssertEqual(world.enemies[0].health, 60)
        XCTAssertEqual(world.gold, 0)
        XCTAssertEqual(world.kills, 0)
    }

    func testAttacksDoNotPassThroughWalls() {
        var world = World(seed: 42)
        world.player.position = Vec2(1.5, 1.3)
        world.enemies = [Enemy(id: 0, position: Vec2(1.5, -0.1), health: 60)]
        world.attack()
        XCTAssertEqual(world.enemies[0].health, 60)
    }

    func testShieldReducesDamageAndPauseFreezesSimulation() {
        var open = World(seed: 42)
        open.enemies = [Enemy(id: 0, position: open.player.position + Vec2(0, -0.6))]
        var shielded = open
        open.step(seconds: 1.0 / 60, input: Input())
        shielded.step(seconds: 1.0 / 60, input: Input(blocking: true))
        XCTAssertLessThan(open.player.health, shielded.player.health)
        let health = shielded.player.health
        let time = shielded.elapsed
        shielded.paused = true
        shielded.step(seconds: 0.1, input: Input(move: Vec2(0, 1)))
        XCTAssertEqual(shielded.elapsed, time)
        XCTAssertEqual(shielded.player.health, health)
    }

    func testExitRequiresVictoryAndStartsNextFloor() {
        var world = World(seed: 42)
        world.player.position = world.dungeon.exit.center
        world.interact()
        XCTAssertEqual(world.floor, 1)
        world.enemies = []
        world.interact()
        XCTAssertEqual(world.floor, 2)
        XCTAssertGreaterThan(world.enemies.count, 0)
        XCTAssertTrue(world.dungeon.canStand(at: world.player.position))
    }

    func testLargeDeltaIsBoundedAndDeathStopsActions() {
        var world = World(seed: 42)
        world.enemies = []
        let p = world.player.position
        world.step(seconds: 100, input: Input(move: Vec2(0, 1)))
        XCTAssertLessThan((world.player.position - p).length, 0.2)
        world.player.health = 0
        let after = world.player.position
        world.step(seconds: 0.05, input: Input(move: Vec2(0, 1)))
        world.attack()
        XCTAssertEqual(world.player.position, after)
        XCTAssertEqual(world.player.attackCooldown, 0)
    }
}
