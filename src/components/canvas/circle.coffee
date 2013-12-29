Stimulus = require("../../stimresp").Stimulus


class Circle extends Stimulus

  defaults:
    x: 0, y: 0, radius: 50, fill: 'red', opacity: 1, origin: "top-left"

  render: (context, layer) ->
    console.log("rendering circle")

    circ = new Kinetic.Circle({ x: 0, y: 0, radius: @spec.radius, fill: @spec.fill, stroke: @spec.stroke, strokeWidth: @spec.strokeWidth, opacity: @spec.opacity })
    coords = @computeCoordinates(context, @spec.position, circ.getWidth(), circ.getHeight())

    ## the origin of a circle in Kinetic.js is at the center of the circle, so the offset computation is incorrect.
    ## we fix the offset by shifting the circle by 1/2 of the width and height
    circ.setPosition({x: coords[0] + circ.getWidth()/2, y: coords[1] + circ.getHeight()/2})


    layer.add(circ)

exports.Circle = Circle