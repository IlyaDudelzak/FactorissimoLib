data:extend({
  {
    type = "item-group",
    name = "factorissimo-group", -- Внутреннее имя
    order = "f",                 -- Порядок вкладки относительно других (f — после боеприпасов)
    icon = "__FactorissimoLib__/graphics/icon/thumbnail.png", -- Путь к иконке вкладки
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
})