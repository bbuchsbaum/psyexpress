Stimulus = require("../../stimresp").Stimulus


class Circle extends Stimulus

  defaults:
    x: 100, y: 100, radius: 50, fill: 'red', opacity: 1

  render: (context, layer) ->
    circ = new Kinetic.Circle({ x: @spec.x, y: @spec.y, radius: @spec.radius, fill: @spec.fill, stroke: @spec.stroke, strokeWidth: @spec.strokeWidth, opacity: @spec.opacity })
    layer.add(circ)

exports.Circle = Circle