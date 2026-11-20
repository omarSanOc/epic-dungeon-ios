import simd

struct Vertex {
    var position: SIMD3<Float>
    var normal: SIMD3<Float>
    var color: SIMD4<Float>
}

struct Mesh {
    var vertices: [Vertex] = []
    mutating func quad(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>, _ d: SIMD3<Float>, color: SIMD4<Float>) {
        let normal = simd_normalize(simd_cross(b - a, c - a))
        for p in [a, b, c, a, c, d] { vertices.append(Vertex(position: p, normal: normal, color: color)) }
    }
    mutating func box(center: SIMD3<Float>, size: SIMD3<Float>, color: SIMD4<Float>) {
        let l = center - size / 2, h = center + size / 2
        let p = [SIMD3(l.x,l.y,l.z), SIMD3(h.x,l.y,l.z), SIMD3(h.x,h.y,l.z), SIMD3(l.x,h.y,l.z),
                 SIMD3(l.x,l.y,h.z), SIMD3(h.x,l.y,h.z), SIMD3(h.x,h.y,h.z), SIMD3(l.x,h.y,h.z)]
        for face in [[0,3,2,1], [4,5,6,7], [0,4,7,3], [1,2,6,5], [3,7,6,2], [0,1,5,4]] {
            quad(p[face[0]], p[face[1]], p[face[2]], p[face[3]], color: color)
        }
    }
    mutating func crystal(center: SIMD3<Float>, radius: Float, height: Float, color: SIMD4<Float>) {
        let top = center + SIMD3(0,height / 2,0)
        let bottom = center - SIMD3(0,height / 2,0)
        for i in 0..<6 {
            let a = Float(i) * .pi / 3, b = Float(i + 1) * .pi / 3
            let p = center + SIMD3(cos(a) * radius,0,sin(a) * radius)
            let q = center + SIMD3(cos(b) * radius,0,sin(b) * radius)
            for points in [[p,top,q], [p,q,bottom]] {
                let n = simd_normalize(simd_cross(points[1] - points[0], points[2] - points[0]))
                vertices += points.map { Vertex(position: $0, normal: n, color: color) }
            }
        }
    }

    static func dungeon(_ map: Dungeon) -> Mesh {
        var mesh = Mesh()
        for z in 0..<map.size {
            for x in 0..<map.size {
                let px = Float(x), pz = Float(z)
                if map.isWall(x, z) {
                    let variation = Float((x * 13 + z * 7) % 5) * 0.018
                    for layer in 0..<4 {
                        mesh.box(center: SIMD3(px + 0.5, Float(layer) * 0.63 + 0.315, pz + 0.5),
                                 size: SIMD3(0.985,0.61,0.985), color: SIMD4(0.26 + variation,0.32 + variation,0.32 + variation,0))
                    }
                    mesh.box(center: SIMD3(px + 0.5,2.52,pz + 0.5), size: SIMD3(1.04,0.12,1.04), color: SIMD4(0.22,0.25,0.25,0))
                } else {
                    let shade: Float = (x + z) % 2 == 0 ? 0.19 : 0.23
                    mesh.box(center: SIMD3(px + 0.5,-0.06,pz + 0.5), size: SIMD3(0.98,0.12,0.98), color: SIMD4(shade,shade + 0.045,shade + 0.05,0))
                }
            }
        }
        mesh.vertices += gateFrame(at: map.exit.center).vertices
        return mesh
    }

    static func gateFrame(at exit: Vec2) -> Mesh {
        var mesh = Mesh()
        let stone = SIMD4<Float>(0.32,0.35,0.32,0)
        let z = exit.y - 0.05
        for offset: Float in [-1.3, 1.3] {
            let x = exit.x + offset
            mesh.box(center: SIMD3(x,1.15,z), size: SIMD3(0.32,2.3,0.45), color: stone)
            mesh.box(center: SIMD3(x,0.14,z), size: SIMD3(0.48,0.28,0.58), color: stone)
        }
        mesh.box(center: SIMD3(exit.x,2.3,z), size: SIMD3(2.95,0.32,0.5), color: stone)
        return mesh
    }

    static func gateSeal(at exit: Vec2, open: Bool) -> Mesh {
        var mesh = Mesh()
        let color = open ? SIMD4<Float>(0.22,0.95,0.78,1) : SIMD4<Float>(0.8,0.29,0.08,0.6)
        for offset: Float in [-0.95,-0.5,0,0.5,0.95] {
            mesh.box(center: SIMD3(exit.x + offset,1.05,exit.y - 0.05), size: SIMD3(0.055,2.0,0.055), color: color)
        }
        mesh.crystal(center: SIMD3(exit.x,2.35,exit.y - 0.5), radius: 0.22, height: 0.52, color: color)
        return mesh
    }

    static func actors(_ world: World) -> Mesh {
        var mesh = Mesh()
        for enemy in world.enemies where enemy.health > 0 {
            let p = SIMD3<Float>(enemy.position.x,0,enemy.position.y)
            let pulse = sin(world.elapsed * 3 + Float(enemy.id)) * 0.035
            let body = enemy.hitFlash > 0 ? SIMD4<Float>(0.95,0.8,0.5,0.3) : SIMD4<Float>(0.27,0.37,0.34,0)
            mesh.box(center: p + SIMD3(-0.17,0.25,0), size: SIMD3(0.24,0.5,0.28), color: body)
            mesh.box(center: p + SIMD3(0.17,0.25,0), size: SIMD3(0.24,0.5,0.28), color: body)
            mesh.box(center: p + SIMD3(0,0.82 + pulse,0), size: SIMD3(0.68,0.68,0.4), color: body)
            mesh.box(center: p + SIMD3(0,1.37 + pulse,0), size: SIMD3(0.4,0.38,0.4), color: body)
            for x: Float in [-0.43, 0.43] {
                mesh.box(center: p + SIMD3(x,0.84 + pulse,0), size: SIMD3(0.22,0.64,0.3), color: body)
            }
            // Eyes appear on both faces, so the abstract sentinel reads from every approach.
            for z: Float in [-0.205,0.205] {
                mesh.box(center: p + SIMD3(0,1.4 + pulse,z), size: SIMD3(0.29,0.055,0.025), color: SIMD4(1,0.46,0.12,1))
                mesh.crystal(center: p + SIMD3(0,0.86 + pulse,z), radius: 0.11, height: 0.3, color: SIMD4(0.25,0.95,0.78,0.7))
            }
        }
        for chest in world.chests {
            let p = SIMD3<Float>(chest.position.x,0.23,chest.position.y)
            mesh.box(center: p, size: SIMD3(0.65,0.46,0.45), color: SIMD4(0.22,0.13,0.075,0))
            mesh.box(center: p + SIMD3(0,chest.opened ? 0.42 : 0.24,0), size: SIMD3(0.69,0.12,0.48), color: SIMD4(0.65,0.4,0.14,0))
            if !chest.opened { mesh.crystal(center: p + SIMD3(0,0.55,0), radius: 0.1, height: 0.23, color: SIMD4(1,0.65,0.2,1)) }
        }
        for p in [SIMD3<Float>(6.1,0,12), SIMD3<Float>(10.9,0,12), SIMD3<Float>(4.6,0,7), SIMD3<Float>(12.4,0,7)] {
            mesh.box(center: p + SIMD3(0,0.42,0), size: SIMD3(0.25,0.84,0.25), color: SIMD4(0.18,0.2,0.2,0))
            mesh.box(center: p + SIMD3(0,0.85,0), size: SIMD3(0.42,0.15,0.42), color: SIMD4(0.49,0.3,0.13,0))
            mesh.crystal(center: p + SIMD3(0,1.1,0), radius: 0.16, height: 0.42 + sin(world.elapsed * 9 + p.x) * 0.07, color: SIMD4(1,0.55,0.12,1))
        }
        mesh.vertices += gateSeal(at: world.dungeon.exit.center, open: world.canAscend).vertices
        return mesh
    }
}
