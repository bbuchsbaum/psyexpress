Stimulus = require("../../stimresp").Stimulus

class FixationCross extends Stimulus

  defaults:
    strokeWidth: 8, length: 150, fill: 'black'

  render: (context, layer) ->
    x = context.width() / 2
    y = context.height() / 2

    horz = new Kinetic.Rect({ x: x - @spec.length / 2, y: y, width: @spec.length, height: @spec.strokeWidth, fill: @spec.fill })
    vert = new Kinetic.Rect({ x: x - @spec.strokeWidth / 2, y: y - @spec.length / 2 + @spec.strokeWidth / 2, width: @spec.strokeWidth, height: @spec.length, fill: @spec.fill })
    group = new Kinetic.Group()
    group.add(horz)
    group.add(vert)

    layer.add(group)

exports.FixationCross = FixationCross