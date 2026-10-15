import Cadova

await Project {
    await Model("hole-mount") {
        Metadata(
            title: "Keystone Hole Mount",
            description: "A threaded mount with a nut that holds keystone modules in a round hole through a panel or desk."
        )

        @Parameter("Hole diameter", in: 30...70, step: 1, unit: "mm", description: "Diameter of the hole the mount goes through")
        var diameter = 44.0

        @Parameter("Cut away walls", description: "Open the sides to make room for inserting modules; needed for smaller holes")
        var cutThrough = false

        // As many modules as fit in the hole, even at the largest tolerance. A hole with room for only
        // one doesn't offer the choice.
        let maxSlotCount = HoleMount(outerDiameter: diameter, cutThrough: cutThrough).maxSlotCount(tolerance: 0.6)
        let slotCount: Int
        if maxSlotCount > 1 {
            @Parameter("Modules", in: 1...maxSlotCount, description: "Number of keystone modules side by side; a larger hole fits more")
            var chosenSlotCount = 1
            slotCount = chosenSlotCount
        } else {
            slotCount = 1
        }

        @Parameter("Max panel thickness", in: 5...40, step: 1, unit: "mm", description: "The thickest panel the mount can clamp")
        var panelThickness = 20.0

        @Parameter("Tolerance", in: 0...0.6, step: 0.05, unit: "mm", description: "Extra clearance for the modules and the thread. The default usually works fine.")
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
