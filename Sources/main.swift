import SwiftSCAD

save(environment: .defaultEnvironment.withTolerance(0.3)) {
    PanelMount(outerDiameter: 30, yOffset: -1.0, cutThrough: true)
    PanelMount(outerDiameter: 32, yOffset: -1.0, cutThrough: true)
    PanelMount(outerDiameter: 38, cutThrough: true)
    PanelMount(outerDiameter: 40)
    PanelMount(outerDiameter: 44)
    PanelMount(outerDiameter: 50)
    PanelMount(outerDiameter: 54)
    PanelMount(outerDiameter: 60)
    PanelMount(outerDiameter: 60, slotCount: 2)
}
