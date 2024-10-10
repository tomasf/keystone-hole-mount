import SwiftSCAD
import Helical
import Keystone

struct PanelMount: Shape3D {
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
        form: TrapezoidalThreadForm(angle: 90°, crestWidth: 0.2)
    )}

    init(outerDiameter: Double, slotCount: Int = 1, yOffset: Double = 0, cutThrough: Bool = false) {
        self.outerDiameter = outerDiameter
        self.slotCount = slotCount
        self.yOffset = yOffset
        self.hasCutout = cutThrough
    }

    var body: any Geometry3D {
        Stack(.x, spacing: 3, alignment: .centerY) {
            main
            nut
        }
        .named(String(
            format:"keystone-mount-%gmm%@",
            outerDiameter,
            slotCount > 1 ? "-\(slotCount)slots" : ""
        ))
    }

    var main: any Geometry3D {
        EnvironmentReader { e in
            let metrics = KeystoneSlot.Metrics(environment: e)
            let latchSize = metrics.latchSpaceSize
            let latchSpaceWidth = latchSize.x + moduleBodyWidth * Double(slotCount - 1)
            let bodyWidthFull = moduleBodyWidth * Double(slotCount) + e.tolerance

            Screw(thread: thread, length: fullLength)
                .rotated(z: 80°)
                .applyingTopEdgeProfile(.chamfer(size: threadDepth + 0.4), method: .convexHull) {
                    Circle(diameter: outerDiameter)
                }
                .adding {
                    Circle(diameter: faceDiameter)
                        .extruded(height: faceThickness, bottomEdge: .chamfer(size: faceThickness), method: .convexHull)
                }
                .subtracting {
                    KeystoneSlot()
                        .rotated(y: 180°)
                        .translated(y: yOffset, z: metrics.baseSize.z)
                        .repeated(along: .x, step: moduleBodyWidth, count: slotCount)
                        .aligned(at: .centerX)

                    let minorCircle = Circle(diameter: thread.minorDiameter - e.tolerance)
                    let majorCircle = Circle(diameter: outerDiameter - e.tolerance)

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
                        .rounded(amount: wallThickness, side: .inside)
                        .extruded(height: fullLength)
                        .translated(z: metrics.baseSize.z)
                }
        }
    }

    var nut: any Geometry3D {
        Circle(diameter: nutOuterDiameter)
            .extruded(height: nutFlangeThickness, topEdge: .fillet(radius: nutCornerRadius), method: .convexHull)
            .adding {
                RegularPolygon(sideCount: 6, circumradius: nutOuterDiameter / 2)
                    .extruded(height: nutThickness, topEdge: .fillet(radius: nutCornerRadius), method: .convexHull)
            }
            .subtracting {
                ThreadedHole(thread: thread, depth: nutThickness, leadinChamferSize: threadDepth * 1.2)
            }
    }
}
