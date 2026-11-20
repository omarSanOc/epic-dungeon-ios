import SwiftUI

private let parchment = Color(red: 0.92, green: 0.88, blue: 0.76)
private let ember = Color(red: 0.94, green: 0.61, blue: 0.28)
private let jade = Color(red: 0.38, green: 0.81, blue: 0.69)
private let ink = Color(red: 0.045, green: 0.075, blue: 0.08)

struct GameScreen: View {
    @StateObject private var model = GameModel()
    @Environment(\.scenePhase) private var phase

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                MetalSurface(model: model).ignoresSafeArea()
                LinearGradient(colors: [.black.opacity(0.4), .clear, .black.opacity(0.68)], startPoint: .top, endPoint: .bottom)
                    .allowsHitTesting(false).ignoresSafeArea()
                if !model.started { welcome(compact: geometry.size.width < 700) }
                else {
                    hud
                    if !model.world.paused && !model.world.isDead { controls }
                    if model.world.paused || model.world.isDead { pausePanel }
                }
                if let error = model.rendererError {
                    VStack(spacing: 18) {
                        Text("RENDERER UNAVAILABLE").font(.headline)
                        Text(error).multilineTextAlignment(.center)
                    }.padding(40).background(ink).foregroundStyle(parchment)
                }
            }
            .foregroundStyle(parchment)
            .background(ink)
            .onChange(of: phase) { _, value in
                if value != .active { model.clearInput(); if model.started { model.world.paused = true } }
            }
        }
        #if os(macOS)
        .frame(minWidth: 820, minHeight: 600)
        #endif
    }

    private func welcome(compact: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 22) {
                Label("AN ORIGINAL NATIVE EXPERIMENT", systemImage: "diamond")
                    .font(.system(size: 10, weight: .medium, design: .monospaced)).tracking(2).foregroundStyle(ember)
                Text("EMBER\nKEEP").font(.system(size: compact ? 56 : 86, weight: .light, design: .serif)).tracking(8).lineSpacing(-12)
                Rectangle().fill(ember).frame(width: 68, height: 2)
                Text("The keep is waking.").font(.system(size: 25, weight: .light, design: .serif))
                Text("Descend into forgotten stone. Defeat its wardens.\nCarry the last ember to the gate.")
                    .font(.system(size: 14)).foregroundStyle(parchment.opacity(0.66)).lineSpacing(6)
                Button(action: model.begin) {
                    HStack(spacing: 38) { Text("ENTER THE KEEP").tracking(2); Image(systemName: "arrow.right") }
                        .font(.system(size: 12, weight: .semibold)).padding(.horizontal, 24).padding(.vertical, 18)
                        .foregroundStyle(ink).background(parchment)
                }.buttonStyle(.plain).accessibilityIdentifier("beginGame")
                Text("SWIFT + METAL    /    PLAYABLE PROTOTYPE 01")
                    .font(.system(size: 9, design: .monospaced)).tracking(1).foregroundStyle(parchment.opacity(0.45))
            }
            .padding(compact ? 28 : 60)
            .background(LinearGradient(colors: [ink.opacity(0.94), ink.opacity(0)], startPoint: .leading, endPoint: .trailing))
            Spacer(minLength: 0)
        }
    }

    private var hud: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("EMBERKEEP").font(.system(size: 20, weight: .light, design: .serif)).tracking(4)
                    Text("THE HOLLOW SPIRE  /  FLOOR \(String(format: "%02d", model.world.floor))")
                        .font(.system(size: 9, design: .monospaced)).tracking(1).foregroundStyle(ember)
                }
                Spacer()
                VStack(spacing: 6) {
                    Text(model.world.canAscend ? "THE GATE IS OPEN" : "BREAK THE SEAL")
                        .font(.system(size: 10, weight: .semibold)).tracking(3)
                    Text("\(model.world.aliveEnemies) wardens remain")
                        .font(.system(size: 11)).foregroundStyle(parchment.opacity(0.6))
                }
                Spacer()
                Label("\(model.world.gold)", systemImage: "diamond.fill").foregroundStyle(ember)
                    .font(.system(size: 17, design: .serif))
            }.padding(28)
            HStack { Spacer(); minimap.padding(.trailing, 28) }
            Spacer()
            Image(systemName: "plus").font(.system(size: 14, weight: .ultraLight)).opacity(0.7)
            Spacer()
            Text(model.world.message).font(.system(size: 12, design: .serif)).foregroundStyle(parchment.opacity(0.75))
                .padding(.bottom, 20)
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack { Text("VITALITY").tracking(2); Spacer(); Text("\(model.world.player.health) / 100") }
                        .font(.system(size: 9, design: .monospaced))
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(parchment.opacity(0.14))
                            Rectangle().fill(model.world.player.health < 30 ? .red.opacity(0.7) : jade)
                                .frame(width: g.size.width * CGFloat(model.world.player.health) / 100)
                        }
                    }.frame(height: 3)
                }.frame(width: 190)
                Spacer()
                #if os(macOS)
                Text("WASD  MOVE     DRAG  LOOK     SPACE  STRIKE     F  GUARD     E  USE")
                    .font(.system(size: 9, design: .monospaced)).foregroundStyle(parchment.opacity(0.5))
                #endif
            }.padding(28)
        }
        .overlay {
            if model.world.player.damageFlash > 0 { Color.red.opacity(0.15).ignoresSafeArea() }
        }
        .allowsHitTesting(false)
    }

    private var minimap: some View {
        Canvas { context, size in
            let map = model.world.dungeon
            let scale = size.width / CGFloat(map.size)
            for y in 0..<map.size {
                for x in 0..<map.size where !map.isWall(x, y) {
                    context.fill(Path(CGRect(x: CGFloat(x) * scale, y: CGFloat(y) * scale, width: scale - 0.8, height: scale - 0.8)), with: .color(parchment.opacity(0.22)))
                }
            }
            let exit = map.exit.center
            context.fill(Path(ellipseIn: CGRect(x: CGFloat(exit.x) * scale - 2, y: CGFloat(exit.y) * scale - 2, width: 4, height: 4)), with: .color(ember))
            for enemy in model.world.enemies where enemy.health > 0 {
                context.fill(Path(ellipseIn: CGRect(x: CGFloat(enemy.position.x) * scale - 1.5, y: CGFloat(enemy.position.y) * scale - 1.5, width: 3, height: 3)), with: .color(.red.opacity(0.8)))
            }
            let p = model.world.player.position
            let center = CGPoint(x: CGFloat(p.x) * scale, y: CGFloat(p.y) * scale)
            context.fill(Path(ellipseIn: CGRect(x: center.x - 2.5, y: center.y - 2.5, width: 5, height: 5)), with: .color(jade))
            var direction = Path(); direction.move(to: center)
            direction.addLine(to: CGPoint(x: center.x + CGFloat(model.world.player.forward.x) * 7, y: center.y + CGFloat(model.world.player.forward.y) * 7))
            context.stroke(direction, with: .color(jade), lineWidth: 1)
        }.frame(width: 105, height: 105).padding(10).background(ink.opacity(0.7))
            .overlay(Rectangle().strokeBorder(parchment.opacity(0.12), lineWidth: 1))
    }

    private var controls: some View {
        ZStack {
            VStack { HStack { Spacer(); Button(action: model.togglePause) { Image(systemName: "pause.fill").padding(12) }.buttonStyle(.plain) }; Spacer() }
                .padding(.top, 86).padding(.trailing, 20)
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    #if os(iOS)
                    joystick
                    Spacer()
                    VStack(spacing: 16) {
                        Text("DRAG RIGHT SIDE TO LOOK").font(.system(size: 8, design: .monospaced)).opacity(0.6)
                        HStack(spacing: 12) {
                            actionButton("USE", icon: "hand.draw", action: { model.world.interact() })
                            actionButton("GUARD", icon: "shield", action: {})
                                .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { _ in model.touchBlock = true }.onEnded { _ in model.touchBlock = false })
                            actionButton("STRIKE", icon: "bolt", action: { model.world.attack() })
                        }
                    }
                    #else
                    Spacer()
                    actionButton("E · USE", icon: "hand.draw", action: { model.world.interact() })
                    actionButton("STRIKE", icon: "bolt", action: { model.world.attack() })
                    #endif
                }.padding(.horizontal, 30).padding(.bottom, 100)
            }
            // A minimal blade silhouette supplies immediate attack/guard feedback without imported art.
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 10, bottomTrailingRadius: 10, topTrailingRadius: 2)
                        .fill(LinearGradient(colors: [parchment.opacity(0.8), .gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: model.world.blocking ? 85 : 13, height: model.world.blocking ? 110 : 165)
                        .rotationEffect(.degrees(model.world.player.attackCooldown > 0.25 ? -55 : -20))
                        .offset(x: -190, y: 25)
                }
            }.allowsHitTesting(false)
        }
    }
    private func actionButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) { Image(systemName: icon).font(.system(size: 19)); Text(title).font(.system(size: 8, weight: .medium)).tracking(1) }
                .frame(width: 66, height: 66).background(ink.opacity(0.85))
                .overlay(Circle().strokeBorder(ember.opacity(0.5), lineWidth: 1)).clipShape(Circle())
        }.buttonStyle(.plain).accessibilityLabel(title)
    }
    private var joystick: some View {
        ZStack {
            Circle().strokeBorder(parchment.opacity(0.22), lineWidth: 1).background(Circle().fill(ink.opacity(0.5)))
            Circle().fill(parchment.opacity(0.3)).frame(width: 42, height: 42)
                .offset(x: CGFloat(model.touchMove.x) * 38, y: CGFloat(-model.touchMove.y) * 38)
        }.frame(width: 114, height: 114).contentShape(Circle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                let vector = Vec2(Float(value.translation.width / 38), Float(-value.translation.height / 38))
                model.touchMove = vector.length > 1 ? vector.normalized : vector
            }.onEnded { _ in model.touchMove = Vec2() })
            .accessibilityLabel("Movement joystick")
    }
    private var pausePanel: some View {
        ZStack {
            ink.opacity(0.8).ignoresSafeArea()
            VStack(spacing: 24) {
                Text(model.world.isDead ? "THE EMBER FADES" : "A MOMENT OF STILLNESS")
                    .font(.system(size: 28, weight: .light, design: .serif)).tracking(3)
                Text(model.world.isDead ? "Floor \(model.world.floor)  ·  \(model.world.kills) wardens  ·  \(model.world.gold) gold" : "Your journey is paused.")
                    .font(.system(size: 13)).opacity(0.65)
                Button(model.world.isDead ? "TRY AGAIN" : "RETURN TO THE KEEP") {
                    if model.world.isDead { model.restart() } else { model.togglePause() }
                }.buttonStyle(.plain).padding(18).background(parchment).foregroundStyle(ink)
            }.padding(30)
        }
    }
}
