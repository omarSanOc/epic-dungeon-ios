import Foundation

struct Vec2: Equatable {
    var x: Float
    var y: Float
    init(_ x: Float = 0, _ y: Float = 0) { self.x = x; self.y = y }
    var length: Float { sqrt(x * x + y * y) }
    var normalized: Vec2 { length > 0.0001 ? self * (1 / length) : Vec2() }
    func dot(_ other: Vec2) -> Float { x * other.x + y * other.y }
    static func + (a: Vec2, b: Vec2) -> Vec2 { Vec2(a.x + b.x, a.y + b.y) }
    static func - (a: Vec2, b: Vec2) -> Vec2 { Vec2(a.x - b.x, a.y - b.y) }
    static func * (a: Vec2, b: Float) -> Vec2 { Vec2(a.x * b, a.y * b) }
}

struct Cell: Hashable {
    var x: Int
    var y: Int
    var center: Vec2 { Vec2(Float(x) + 0.5, Float(y) + 0.5) }
}

struct SeededRandom {
    var state: UInt64
    mutating func next(_ upperBound: Int) -> Int {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Int((state >> 32) % UInt64(upperBound))
    }
}
