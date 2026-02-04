local PERMABLACK_SURFACES = {
    ["tenebris-factory-floor"] = true,
    ["maraxsis-trench-factory-floor"] = true,
}

function factorissimo.build_lights_upgrade(factory)
    if not factory.inside_surface.valid then return end
    local force = factory.force
    if not force.valid then return end
    local has_tech = force.technologies["factory-interior-upgrade-lights"].researched

    factory.inside_surface.freeze_daytime = true
end