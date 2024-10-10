import SwiftSCAD

save(environment: .defaultEnvironment.withTolerance(0.3)) {
    HoleMount(outerDiameter: 30, yOffset: -1.0, cutThrough: true)
    HoleMount(outerDiameter: 32, yOffset: -1.0, cutThrough: true)
    HoleMount(outerDiameter: 38, cutThrough: true)
    HoleMount(outerDiameter: 40)
    HoleMount(outerDiameter: 44)
    HoleMount(outerDiameter: 50)
    HoleMount(outerDiameter: 54)
    HoleMount(outerDiameter: 60)
    HoleMount(outerDiameter: 60, slotCount: 2)
}
