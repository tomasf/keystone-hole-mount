import Cadova

let mounts = [
    HoleMount(outerDiameter: 30, yOffset: -1.0, cutThrough: true),
    HoleMount(outerDiameter: 32, yOffset: -1.0, cutThrough: true),
    HoleMount(outerDiameter: 38, cutThrough: true),
    HoleMount(outerDiameter: 40, cutThrough: true),
    HoleMount(outerDiameter: 44),
    HoleMount(outerDiameter: 50),
    HoleMount(outerDiameter: 54),
    HoleMount(outerDiameter: 60),
    HoleMount(outerDiameter: 60, slotCount: 2),
]

await Project {
    for mount in mounts {
        await Model(mount.name) {
            mount
        }
    }
} environment: {
    $0.tolerance = 0.3
}
