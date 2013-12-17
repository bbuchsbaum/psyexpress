Stimulus = require("../../stimresp").Stimulus

class Arrow extends Stimulus

  defaults:
    x: 100, y: 100, length: 100, angle: 0, thickness: 40, fill: "red", arrowSize: 50

  render: (context, layer) ->
    rect = new Kinetic.Rect({x: 0, y: 0, width: @spec.length, height: @spec.thickness, fill: @spec.fill, stroke: @spec.stroke, strokeWidth: @spec.strokeWidth, opacity: @spec.opacity})

    _this = @

    triangle = new Kinetic.Shape({
      drawFunc: (cx) ->
        cx.beginPath()

        cx.moveTo(_this.spec.length, -_this.spec.arrowSize / 2.0)

        cx.lineTo(_this.spec.length + _this.spec.arrowSize, _this.spec.thickness / 2.0)

        cx.lineTo(_this.spec.length, _this.spec.thickness + _this.spec.arrowSize / 2.0)

        cx.closePath()
        cx.fillStrokeShape(this)

      fill: _this.spec.fill
      stroke: @spec.stroke
      strokeWidth: @spec.strokeWidth
      opacity: @spec.opacity

    })

    group = new Kinetic.Group({x: @spec.x, y: @spec.y, rotationDeg: @spec.angle, offset: [0, @spec.thickness / 2.0]})
    group.add(rect)
    group.add(triangle)
    layer.add(group)

exports.Arrow = Arrow

