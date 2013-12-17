Stimulus = require("../../stimresp").Stimulus

class Background extends Stimulus

  constructor: (@stims = [], @fill = "white") ->
    super({}, {})

  render: (context, layer) ->
    background = new Kinetic.Rect({
      x: 0,
      y: 0,
      width: context.width(),
      height: context.height(),
      name: 'background'
      fill: @fill
    })


    layer.add(background)

    for stim in @stims
      stim.render(context, layer)


exports.Background = Background