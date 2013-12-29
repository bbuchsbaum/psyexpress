Stimulus = require("../../stimresp").Stimulus


class GridLines extends Stimulus

  defaults:
    x: 0, y: 0, rows: 3, cols: 3, stroke: "black", strokeWidth: 2


  render: (context, layer) ->

    for i in [0..@spec.rows]
      y = @spec.y + (i * context.height() / @spec.rows)
      line = new Kinetic.Line({
        points: [@spec.x, y, @spec.x + context.width(), y]
        stroke: @spec.stroke
        strokeWidth: @spec.strokeWidth
        dashArray: @spec.dashArray
      })

      layer.add(line)

    for i in [0..@spec.cols]
      x = @spec.x + (i * context.width() / @spec.cols)
      line = new Kinetic.Line({
        points: [x, @spec.y, x, @spec.y + context.height()]
        stroke: @spec.stroke
        strokeWidth: @spec.strokeWidth
        dashArray: @spec.dashArray
      })

      layer.add(line)


exports.GridLines = GridLines