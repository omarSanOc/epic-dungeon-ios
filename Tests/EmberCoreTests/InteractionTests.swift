import XCTest
@testable import EmberCore

final class InteractionTests: XCTestCase {
    func testCacheRewardsOnceAndPausedOrDeadPlayersCannotUseIt() {
        var world = World()
        world.player.position = world.chests[0].position + Vec2(0.55, 0)
        world.player.health = 90
        world.paused = true
        world.interact()
        XCTAssertFalse(world.chests[0].opened)
        world.paused = false
        world.player.health = 0
        world.interact()
        XCTAssertFalse(world.chests[0].opened)
        XCTAssertEqual(world.gold, 0)
        XCTAssertEqual(world.player.health, 0)
        world.player.health = 90
        world.interact()
        XCTAssertTrue(world.chests[0].opened)
        XCTAssertEqual(world.gold, 18)
        XCTAssertEqual(world.player.health, 100)
        world.player.health = 75
        world.interact()
        XCTAssertEqual(world.gold, 18)
        XCTAssertEqual(world.player.health, 75)
    }

    func testFloorTransitionPreservesRewardsAndRepopulates() {
        var world = World()
        world.player.position = world.dungeon.exit.center + Vec2(0, 0.55)
        world.player.health = 64
        world.gold = 58
        world.kills = 4
        world.chests[0].opened = true
        for i in world.enemies.indices { world.enemies[i].health = 0 }
        world.interact()
        XCTAssertEqual(world.floor, 2)
        XCTAssertEqual(world.player.health, 84)
        XCTAssertEqual(world.gold, 58)
        XCTAssertEqual(world.kills, 4)
        XCTAssertEqual(world.aliveEnemies, 4)
        XCTAssertTrue(world.enemies.allSatisfy { $0.health == 70 })
        XCTAssertTrue(world.chests.allSatisfy { !$0.opened })
        XCTAssertEqual(world.player.position, world.dungeon.start.center)
        XCTAssertFalse(world.canAscend)
        world.interact()
        XCTAssertEqual(world.floor, 2)
    }

    func testEnemyAttackRespectsCooldownAndRearGuardDoesNotReduceDamage() {
        var world = World()
        let p = world.player.position
        world.enemies = [Enemy(id: 0, position: p + Vec2(0, 0.6))]
        world.step(seconds: 0.05, input: Input(blocking: true))
        XCTAssertEqual(world.player.health, 88)
        for _ in 0..<20 { world.step(seconds: 0.05, input: Input(blocking: true)) }
        XCTAssertEqual(world.player.health, 88)
        for _ in 0..<8 { world.step(seconds: 0.05, input: Input(blocking: true)) }
        XCTAssertEqual(world.player.health, 76)
    }
}
