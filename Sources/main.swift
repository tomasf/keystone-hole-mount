import Cadova

await Project {
    await Model("hole-mount") {
        Metadata(
            title: "Keystone Hole Mount",
            description: "A threaded mount with a nut that holds keystone modules in a round hole through a panel or desk."
        )

        @Parameter("Hole diameter", in: 30...70, step: 1, unit: "mm", description: "Diameter of the hole the mount goes through")
        var diameter = 44.0

        @Parameter("Modules", in: 1...3, description: "Number of keystone modules side by side; more need a larger hole")
        var slotCount = 1

        @Parameter("Max panel thickness", in: 5...40, step: 1, unit: "mm", description: "The thickest panel the mount can clamp")
        var panelThickness = 20.0

        @Parameter("Cut away walls", description: "Open the sides to make room for inserting modules; needed for smaller holes")
        var cutThrough = false

        @Parameter("Tolerance", in: 0...0.6, step: 0.05, unit: "mm", description: "Extra clearance for the modules and the thread")
        var tolerance = 0.3

        Environment {
            $0.tolerance = tolerance
        }

        HoleMount(
            outerDiameter: diameter,
            slotCount: slotCount,
            // The smallest holes have room for a module only slightly off center
            yOffset: diameter <= 32 ? -1.0 : 0,
            maxPanelThickness: panelThickness,
            cutThrough: cutThrough
        )
    }
}
