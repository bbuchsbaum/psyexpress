Stimulus = require("../../stimresp").Stimulus

class CanvasBorder extends Stimulus

  defaults:
    strokeWidth: 5, stroke: "black"

  render: (context, layer) ->
    border = new Kinetic.Rect({ x: 0, y: 0, width: context.width(), height: context.height(), strokeWidth: @spec.strokeWidth, stroke: @spec.stroke })
    layer.add(border)


exports.CanvasBorder = CanvasBorder

