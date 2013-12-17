
Stimulus = require("../../stimresp").Stimulus


class Blank extends Stimulus

  defaults:
    fill: "white"

  render: (context, layer) ->
    blank = new Kinetic.Rect({ x: 0, y: 0, width: context.width(), height: context.height(), fill: @spec.fill })
    layer.add(blank)


exports.Blank = Blank






