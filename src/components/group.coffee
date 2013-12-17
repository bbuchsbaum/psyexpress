Stimulus = require("../stimresp").Stimulus


class Group extends Stimulus

  constructor: (@stims, layout) ->
    super({})

    if layout
      @layout = layout
      for stim in @stims
        stim.layout = layout

  render: (context, layer) ->
    for stim in @stims
      stim.render(context, layer)


exports.Group = Group