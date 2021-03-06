Stimulus = require("../../stimresp").Stimulus


class Rectangle extends Stimulus

  defaults:
    x: 0, y: 0, width: 100, height: 100, fill: 'red'

  constructor: (spec = {}) ->
    super(spec)



  render: (context, layer) ->
    coords = @computeCoordinates(context, @spec.position, @spec.width, @spec.height)
    rect = new Kinetic.Rect({ x: coords[0], y: coords[1], width: @spec.width, height: @spec.height, fill: @spec.fill, stroke: @spec.stroke, strokeWidth: @spec.strokeWidth })
    layer.add(rect)

exports.Rectangle = Rectangle