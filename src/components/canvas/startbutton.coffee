Stimulus = require("../../stimresp").Stimulus

class StartButton extends Stimulus

  defaults:
    width: 150, height: 75

  render: (context, layer) ->
    xcenter = context.width() / 2
    ycenter = context.height() / 2

    group = new Kinetic.Group({id: @spec.id})

    text = new Kinetic.Text({text: "Start", x: xcenter - @spec.width / 2, y: ycenter - @spec.height / 2, width: @spec.width, height: @spec.height, fontSize: 30, fill: "white", fontFamily: "Arial", align: "center", padding: 20})
    button = new Kinetic.Rect({x: xcenter - @spec.width / 2, y: ycenter - text.getHeight() / 2, width: @spec.width, height: text.getHeight(), fill: "black", cornerRadius: 10, stroke: "LightSteelBlue", strokeWidth: 5})
    group.add(button)
    group.add(text)

    layer.add(group)

exports.StartButton = StartButton