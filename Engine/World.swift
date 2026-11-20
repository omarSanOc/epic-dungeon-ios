import Foundation

struct Input {
    var move = Vec2()
    var turn: Float = 0
    var blocking = false
}
struct Player {
    var position: Vec2
    var yaw: Float = 0
    var health = 100
    var attackCooldown: Float = 0
    var damageFlash: Float = 0
    var forward: Vec2 { Vec2(sin(yaw), -cos(yaw)) }
}
struct Enemy: Identifiable {
    var id: Int
    var position: Vec2
    var health = 60
    var cooldown: Float = 0
    var hitFlash: Float = 0
}
struct Chest: Identifiable {
    var id: Int
    var position: Vec2
    var opened = false
}

struct World {
    let seed: UInt64
    var dungeon: Dungeon
    var player: Player
    var enemies: [Enemy] = []
    var chests: [Chest] = []
    var floor = 1
    var gold = 0
    var kills = 0
    var elapsed: Float = 0
    var paused = false
    var blocking = false
    var message = "Find the wardens. Claim the ember gate."
    var aliveEnemies: Int { enemies.filter { $0.health > 0 }.count }
    var isDead: Bool { player.health <= 0 }
    var canAscend: Bool { aliveEnemies == 0 }

    init(seed: UInt64 = 7381) {
        self.seed = seed
        dungeon = Dungeon(seed: seed)
        player = Player(position: dungeon.start.center)
        populate()
    }
    private mutating func populate() {
        let positions = [Vec2(8.5, 9.5), Vec2(5.5, 7.5), Vec2(11.5, 7.5), Vec2(8.5, 4.5)]
        enemies = positions.enumerated().map { Enemy(id: $0.offset, position: $0.element, health: 60 + (floor - 1) * 10) }
        chests = [Chest(id: 0, position: Vec2(5.5, 13.5)), Chest(id: 1, position: Vec2(10.5, 3.5))]
    }
    mutating func step(seconds: Float, input: Input) {
        guard !paused, !isDead, seconds.isFinite, seconds > 0 else { return }
        // Clamp resumed/background frames to avoid teleportation and accumulated damage.
        let dt = min(seconds, 0.05)
        elapsed += dt
        blocking = input.blocking
        player.attackCooldown = max(0, player.attackCooldown - dt)
        player.damageFlash = max(0, player.damageFlash - dt)
        player.yaw += input.turn * dt
        let movement = input.move.length > 1 ? input.move.normalized : input.move
        let right = Vec2(cos(player.yaw), sin(player.yaw))
        let speed: Float = blocking ? 1.1 : 2.4
        let delta = (right * movement.x + player.forward * movement.y) * (dt * speed)
        player.position = dungeon.slidingMove(from: player.position, by: delta)
        for i in enemies.indices where enemies[i].health > 0 {
            enemies[i].cooldown = max(0, enemies[i].cooldown - dt)
            enemies[i].hitFlash = max(0, enemies[i].hitFlash - dt)
            let toward = player.position - enemies[i].position
            guard toward.length < 6, dungeon.hasLineOfSight(from: enemies[i].position, to: player.position) else { continue }
            if toward.length > 0.85 {
                enemies[i].position = dungeon.slidingMove(from: enemies[i].position, by: toward.normalized * (dt * 0.72))
            } else if enemies[i].cooldown == 0 {
                let facing = player.forward.dot(toward.normalized * -1) > 0.25
                player.health = max(0, player.health - (blocking && facing ? 3 : 12))
                player.damageFlash = 0.25
                enemies[i].cooldown = 1.3
            }
        }
    }
    mutating func attack() {
        guard !paused, !isDead, player.attackCooldown <= 0 else { return }
        player.attackCooldown = 0.48
        let targets = enemies.indices.filter { i in
            let delta = enemies[i].position - player.position
            return enemies[i].health > 0 && delta.length < 1.65 && player.forward.dot(delta.normalized) > 0.55
                && dungeon.hasLineOfSight(from: player.position, to: enemies[i].position)
        }
        guard let i = targets.min(by: { (enemies[$0].position - player.position).length < (enemies[$1].position - player.position).length }) else { return }
        enemies[i].health = max(0, enemies[i].health - 30)
        enemies[i].hitFlash = 0.22
        if enemies[i].health == 0 {
            gold += 10
            kills += 1
            message = canAscend ? "The ember gate is open. Ascend." : "Warden defeated. +10 gold"
        }
    }
    mutating func interact() {
        guard !paused, !isDead else { return }
        if let i = chests.firstIndex(where: { !$0.opened && ($0.position - player.position).length < 1.6
            && dungeon.hasLineOfSight(from: player.position, to: $0.position) }) {
            chests[i].opened = true
            gold += 18
            player.health = min(100, player.health + 25)
            message = "Ember cache: +18 gold, +25 vitality"
        } else if (dungeon.exit.center - player.position).length < 1.6 {
            guard canAscend else { message = "Defeat the remaining wardens to break the seal."; return }
            floor += 1
            dungeon = Dungeon(seed: seed &+ UInt64(floor))
            player.position = dungeon.start.center
            player.health = min(100, player.health + 20)
            player.yaw = 0
            populate()
            message = "Floor \(floor). The keep remembers."
        } else {
            message = "Move closer to a cache or the ember gate."
        }
    }
}
