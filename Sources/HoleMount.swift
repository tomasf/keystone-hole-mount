import Cadova
import Helical
import Keystone

struct HoleMount: Geometry3D {
    let outerDiameter: Double
    let slotCount: Int
    let hasCutout: Bool // For smaller sizes where you need to cut away the walls to make room for inserting the module
    let yOffset: Double

    var faceDiameter: Double { outerDiameter + 10 }
    let faceThickness = 1.0

    let maxPanelThickness: Double
    var fullLength: Double { maxPanelThickness + nutThickness * 0.8 }
    let moduleBodyWidth = 18.0
    let moduleSpacing: Double
    let wallThickness = 3.0

    let nutFlangeWidth = 6.0
    let nutFlangeThickness = 1.0
    let nutThickness = 10.0
    let nutCornerRadius = 1.0
    var nutOuterDiameter: Double { outerDiameter + 2 * nutFlangeWidth }

    let threadDepth = 1.0

    @Environment(\.keystoneSlotMetrics) var metrics
    @Environment(\.tolerance) var tolerance
    var thread: ScrewThread { .init(
        pitch: 4.0,
        majorDiameter: outerDiameter,
        minorDiameter: outerDiameter - 2 * threadDepth,
        form: TrapezoidalThreadform(angle: 90°, crestWidth: 0.2)
    )}

    init(outerDiameter: Double, slotCount: Int = 1, moduleSpacing: Double = 18, yOffset: Double = 0, maxPanelThickness: Double = 20, cutThrough: Bool = false) {
        self.outerDiameter = outerDiameter
        self.slotCount = slotCount
        self.moduleSpacing = moduleSpacing
        self.yOffset = yOffset
        self.maxPanelThickness = maxPanelThickness
        self.hasCutout = cutThrough
    }

    var body: any Geometry3D {
        Stack(.x, spacing: 3, alignment: .centerY) {
            main
            nut
        }
    }

    /// The most modules the mount has room for at the given tolerance, and always at least one
    func maxSlotCount(tolerance: Double) -> Int {
        let room = moduleRoom(tolerance: tolerance)
        var fitting = Int((room.centers / moduleSpacing).rounded(.down)) + 1
        if let bodies = room.bodies {
            fitting = min(fitting, Int((bodies / moduleSpacing).nextDown.rounded(.down)) + 1)
        }
        return max(1, fitting)
    }

    /// The widest spacing at which this many modules fit at the given tolerance, in steps of 0.5 mm
    func maxModuleSpacing(tolerance: Double) -> Double {
        guard slotCount > 1 else { return moduleSpacing }
        let room = moduleRoom(tolerance: tolerance)
        let gaps = Double(slotCount - 1)
        var spacing = room.centers / gaps
        if let bodies = room.bodies {
            spacing = min(spacing, (bodies / gaps).nextDown)
        }
        return (spacing * 2).rounded(.down) / 2
    }

    /// How far modules' corners keep from the thread's root, so their openings don't cut through it
    private let minimumThreadWall = 1.0

    /// How far apart the outermost modules' centers can be: as far as keeps every module's corners
    /// clear of the thread's root, and with the walls cut away, the bodies within the hole
    private func moduleRoom(tolerance: Double) -> (centers: Double, bodies: Double?) {
        let metrics = KeystoneSlot.Metrics(environment: .defaultEnvironment.withTolerance(tolerance))
        let radius = (thread.minorDiameter - tolerance) / 2 - minimumThreadWall
        let cornerY = metrics.baseSize.y / 2 + abs(yOffset)
        let cornerX = (radius * radius - cornerY * cornerY).squareRoot()
        let centers = 2 * cornerX - metrics.baseSize.x
        let bodies = hasCutout ? outerDiameter - 2 * tolerance - moduleBodyWidth : nil
        return (centers, bodies)
    }

    /// The number of modules to make room for: as many as asked for, as long as they fit
    var fittingSlotCount: Int {
        min(slotCount, maxSlotCount(tolerance: tolerance))
    }

    @GeometryBuilder3D
    var main: any Geometry3D {
        let latchSize = metrics.latchSpaceSize
        let slotCount = fittingSlotCount
        let latchSpaceWidth = latchSize.x + moduleSpacing * Double(slotCount - 1)
        let bodyWidthFull = moduleSpacing * Double(slotCount - 1) + moduleBodyWidth + tolerance

        Screw(thread: thread, length: fullLength)
            .rotated(z: 80°)
            .adding {
                Circle(diameter: faceDiameter)
                    .extruded(height: faceThickness, bottomEdge: .chamfer(depth: faceThickness))
            }
            .subtracting {
                EdgeProfile.chamfer(depth: threadDepth + 0.4)
                    .negativeShape
                    .translated(x: outerDiameter / 2)
                    .revolved()
                    .translated(z: fullLength)

                KeystoneSlot()
                    .rotated(y: 180°)
                    .translated(y: yOffset, z: metrics.baseSize.z)
                    .repeated(along: .x, step: moduleSpacing, count: slotCount)
                    .aligned(at: .centerX)

                let minorCircle = Circle(diameter: thread.minorDiameter - tolerance)
                let majorCircle = Circle(diameter: outerDiameter - tolerance)

                for i in 0..<slotCount {
                    let x1 = (-latchSpaceWidth / 2) + moduleSpacing * Double(i)
                    let p1 = Vector2D(x1, minorCircle.correspondingCoordinate(for: x1))
                    let p2 = Vector2D(x1 + latchSize.x, minorCircle.correspondingCoordinate(for: x1 + latchSize.x))

                    Box([p1.distance(to: p2), metrics.baseSize.x, latchSize.z])
                        .aligned(at: .top)
                        .rotated(x: 45°)
                        .rotated(z: p1.angle(to: p2))
                        .translated(x: p1.x, y: p1.y, z: metrics.latchDistanceFromFront)
                }

                Circle(diameter: thread.minorDiameter - 2 * wallThickness)
                    .adding {
                        if hasCutout {
                            Rectangle([bodyWidthFull, outerDiameter])
                                .aligned(at: .center)

                            Rectangle([outerDiameter, outerDiameter])
                                .aligned(at: .centerX)
                                .translated(y: majorCircle.correspondingCoordinate(for: bodyWidthFull / 2))
                                .symmetry(over: .y)
                        }
                    }
                    .rounded(insideRadius: wallThickness)
                    .extruded(height: fullLength)
                    .translated(z: metrics.baseSize.z)
            }
    }

    var nut: any Geometry3D {
        Circle(diameter: nutOuterDiameter)
            .extruded(height: nutFlangeThickness, topEdge: .fillet(radius: nutCornerRadius))
            .adding {
                RegularPolygon(sideCount: 6, circumradius: nutOuterDiameter / 2)
                    .extruded(height: nutThickness, topEdge: .fillet(radius: nutCornerRadius))
            }
            .subtracting {
                ThreadedHole(thread: thread, depth: nutThickness, leadIns: .leading(.constant(depth: threadDepth * 1.2)))
            }
    }
}
