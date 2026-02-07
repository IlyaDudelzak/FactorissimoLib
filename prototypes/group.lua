data:extend({
  {
    type = "item-group",
    name = "factorissimo-group", -- Internal name
    order = "f",                 -- Order of the tab
    icon = "__FactorissimoLib__/graphics/icon/thumbnail.png", -- Path to the tab icon
    icon_size = 256,
  },
})

data:extend({
  {
    type = "item-subgroup",
    name = "factorissimo-factories",
    group = "factorissimo-group",
    order = "a",
  },
  {
    type = "item-subgroup",
    name = "factorissimo-parts",
    group = "factorissimo-group",
    order = "b",
  },
  {
    type = "item-subgroup",
    name = "factorissimo-air-probes",
    group = "factorissimo-group",
    order = "c",
  },
  {
    type = "item-subgroup",
    name = "factorissimo-tiles",
    group = "factorissimo-group",
    order = "d",
  },
  {
    type = "item-subgroup",
    name = "factorissimo-energy-interfaces",
    group = "factorissimo-group",
    order = "y",
  },
  {
    type = "item-subgroup",
    name = "factorissimo-connection-indicators",
    group = "factorissimo-group",
    order = "z",
  },
  {
    type = "item-subgroup",
    name = "factorissimo-factory-floors",
    group = "factorissimo-group",
    order = "za",
  },
  {
    type = "item-subgroup",
    name = "factorissimo-roboports",
    group = "factorissimo-group",
    order = "zb",
  },
})

data:extend({
    {
        type = "recipe-category",
        name = "factory-conditioning"
    }
})