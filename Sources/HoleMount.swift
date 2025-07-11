import Cadova
import Helical
import Keystone

struct HoleMount: Shape3D {
    let outerDiameter: Double
    let slotCount: Int
    let hasCutout: Bool // For smaller sizes where you need to cut away the walls to make room for inserting the module
    let yOffset: Double

    var faceDiameter: Double { outerDiameter + 10 }
    let faceThickness = 1.0

    let maxPanelThickness = 20.0
    var fullLength: Double { maxPanelThickness + nutThickness * 0.8 }
    let moduleBodyWidth = 18.0
    let wallThickness = 3.0

    let nutFlangeWidth = 6.0
    let nutFlangeThickness = 1.0
    let nutThickness = 10.0
    let nutCornerRadius = 1.0
    var nutOuterDiameter: Double { outerDiameter + 2 * nutFlangeWidth }

    let threadDepth = 1.0
    var thread: ScrewThread { .init(
        pitch: 4.0,
        majorDiameter: outerDiameter,
        minorDiameter: outerDiameter - 2 * threadDepth,
        form: TrapezoidalThreadform(angle: 90°, crestWidth: 0.2)
    )}

    init(outerDiameter: Double, slotCount: Int = 1, yOffset: Double = 0, cutThrough: Bool = false) {
        self.outerDiameter = outerDiameter
        self.slotCount = slotCount
        self.yOffset = yOffset
        self.hasCutout = cutThrough
    }

    var name: String {
        String(
            format:"keystone-mount-%gmm%@",
            outerDiameter,
            slotCount > 1 ? "-\(slotCount)slots" : ""
        )
    }

    var body: any Geometry3D {
        Stack(.x, spacing: 3, alignment: .centerY) {
            main
            nut
        }
    }

    var main: any Geometry3D {
        readEnvironment(\.keystoneSlotMetrics, \.tolerance) { metrics, tolerance in
            let latchSize = metrics.latchSpaceSize
            let latchSpaceWidth = latchSize.x + moduleBodyWidth * Double(slotCount - 1)
            let bodyWidthFull = moduleBodyWidth * Double(slotCount) + tolerance

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
                        .repeated(along: .x, step: moduleBodyWidth, count: slotCount)
                        .aligned(at: .centerX)

                    let minorCircle = Circle(diameter: thread.minorDiameter - tolerance)
                    let majorCircle = Circle(diameter: outerDiameter - tolerance)

                    for i in 0..<slotCount {
                        let x1 = (-latchSpaceWidth / 2) + moduleBodyWidth * Double(i)
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
    }

    var nut: any Geometry3D {
        Circle(diameter: nutOuterDiameter)
            .extruded(height: nutFlangeThickness, topEdge: .fillet(radius: nutCornerRadius))
            .adding {
                RegularPolygon(sideCount: 6, circumradius: nutOuterDiameter / 2)
                    .extruded(height: nutThickness, topEdge: .fillet(radius: nutCornerRadius))
            }
            .subtracting {
                ThreadedHole(thread: thread, depth: nutThickness, leadinChamferSize: threadDepth * 1.2)
            }
    }
}
