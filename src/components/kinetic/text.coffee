Stimulus = require("../../stimresp").Stimulus
layout = require("../../layout")

class Text extends Stimulus

  defaults:
    content: "Text", x: 5, y: 5, width: null, fill: "black", fontSize: 40, fontFamily: "Arial", lineHeight: 2, textAlign: "center", position: null

  constructor: (spec = {}) ->
    super(spec)
    if (_.isArray(@spec.content))
      @spec.content = @spec.content.join("\n")

  render: (context, layer) ->
    text = new Kinetic.Text({
      x: @spec.x,
      y: @spec.y,
      text: @spec.content,
      fontSize: @spec.fontSize,
      fontFamily: @spec.fontFamily,
      fill: @spec.fill
      lineHeight: @spec.lineHeight
      width: @spec.width or context.width()
      listening: false
      align: @spec.textAlign
    })

    if @spec.position
      xy = layout.positionToCoord(@spec.position, -text.getWidth() / 2, -text.getHeight() / 2, context.width(), context.height(),
        [@spec.x, @spec.y])
      text.setPosition({x: xy[0], y: xy[1]})


    layer.add(text)


exports.Text = Text