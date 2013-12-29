Stimulus = require("../stimresp").Stimulus


class Viewport extends Stimulus

  ###

  defaults:
    x: 0, y: 0, width: 100, height: 100

  constructor: (@child) ->
    super({})

    @layer = new Kinetic.Layer({
      x: @spec.x
      y: @spec.y
      width: @spec.width
      height: @spec.height
      clip: [0, 0, @spec.width, 100]
    }

  render: (context, layer) ->
    for stim in @stims
      stim.render(context, layer)

###

