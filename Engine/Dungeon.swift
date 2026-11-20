import Foundation

struct Dungeon {
    let size = 17
    private(set) var tiles: [Bool]
    let start = Cell(x: 8, y: 14)
    let exit = Cell(x: 8, y: 2)

    init(seed: UInt64) {
        tiles = Array(repeating: true, count: 17 * 17)
        var random = SeededRandom(state: seed)
        var stack = [Cell(x: 1, y: 1)]
        carve(1, 1)
        while let current = stack.last {
            let candidates = [(0, -2), (2, 0), (0, 2), (-2, 0)].map {
                Cell(x: current.x + $0.0, y: current.y + $0.1)
            }.filter { $0.x > 0 && $0.y > 0 && $0.x < size - 1 && $0.y < size - 1 && isWall($0.x, $0.y) }
            if candidates.isEmpty { stack.removeLast(); continue }
            let next = candidates[random.next(candidates.count)]
            carve((current.x + next.x) / 2, (current.y + next.y) / 2)
            carve(next.x, next.y)
            stack.append(next)
        }
        // Connected chambers and a central nave give the first slice readable landmarks.
        for y in 11...15 { for x in 5...11 { carve(x, y) } }
        for y in 6...9 { for x in 4...12 { carve(x, y) } }
        for y in 1...4 { for x in 6...10 { carve(x, y) } }
        for y in 2...14 { for x in 7...9 { carve(x, y) } }
    }

    private mutating func carve(_ x: Int, _ y: Int) { tiles[y * size + x] = false }
    func isWall(_ x: Int, _ y: Int) -> Bool {
        x < 0 || y < 0 || x >= size || y >= size || tiles[y * size + x]
    }
    func canStand(at p: Vec2, radius: Float = 0.22) -> Bool {
        for dy in [-radius, radius] {
            for dx in [-radius, radius] {
                if isWall(Int(floor(p.x + dx)), Int(floor(p.y + dy))) { return false }
            }
        }
        return true
    }
    func slidingMove(from p: Vec2, by delta: Vec2) -> Vec2 {
        var result = p
        let x = Vec2(p.x + delta.x, p.y)
        if canStand(at: x) { result.x = x.x }
        let y = Vec2(result.x, p.y + delta.y)
        if canStand(at: y) { result.y = y.y }
        return result
    }
    func hasLineOfSight(from a: Vec2, to b: Vec2) -> Bool {
        let steps = max(1, Int((b - a).length / 0.08))
        for i in 0...steps {
            let p = a + (b - a) * (Float(i) / Float(steps))
            if isWall(Int(floor(p.x)), Int(floor(p.y))) { return false }
        }
        return true
    }
    func neighbors(_ cell: Cell) -> [Cell] {
        [(0, -1), (1, 0), (0, 1), (-1, 0)].map {
            Cell(x: cell.x + $0.0, y: cell.y + $0.1)
        }.filter { !isWall($0.x, $0.y) }
    }
    func reachableTiles(from start: Cell) -> Set<Cell> {
        var visited: Set<Cell> = [start]
        var queue = [start]
        var index = 0
        while index < queue.count {
            for next in neighbors(queue[index]) where visited.insert(next).inserted { queue.append(next) }
            index += 1
        }
        return visited
    }
}
