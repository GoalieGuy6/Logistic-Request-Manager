require 'defines'

data:extend({
    {
        type = "bool-setting",
        name = lrm.settings.persistent_empty_template,
        setting_type = "runtime-per-user",
        default_value = "true",
        order = "1"
    },
    {
        type = "int-setting",
        name = lrm.settings.empty_template_size,
        setting_type = "runtime-per-user",
--        minimum_value = 9,
        allowed_values = {9,19,29,39,49,59,69,79,89,99},
        default_value = 49,
        order = "2"
    }
})