require 'defines'

data:extend(
{
  {
    type = "shortcut",
    name = "shortcut-LRM-input-toggle-gui",
    order = "a-a",
    action = "lua",
    --toggleable = true,
    localised_name = {"controls.LRM-input-toggle-gui"},
    associated_control_input = "LRM-input-toggle-gui",
    icon =
    {
      filename = "__base__/graphics/icons/logistic-robot.png",
      priority = "extra-high-no-scale",
      size = 64,
      mipmap_count = 4,
      flags = {"gui-icon"}
    }
  }
})
