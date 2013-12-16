Stimulus = require("../../stimresp").Stimulus
utils = require("../../utils")

class TextInput extends Stimulus
  defaults:
    x: 100, y: 100, width: 200, height: 40, defaultValue: "", fill: "#FAF5E6", stroke: "#0099FF", strokeWidth: 1, content: ""

  constructor: (spec = {}) ->
    super(spec)
    utils.disableBrowserBack()


  getChar: (e) ->
    # key is not shift
    if e.keyCode != 16
      # key is a letter
      if e.keyCode >= 65 && e.keyCode <= 90
        if e.shiftKey
          String.fromCharCode(e.keyCode)
        else
          String.fromCharCode(e.keyCode + 32)
      else if e.keyCode >= 48 && e.keyCode <= 57
        String.fromCharCode(e.keyCode)
      else
        #console.log("key code is",e.keyCode)
        switch e.keyCode
          when 186 then ";"
          when 187 then "="
          when 188 then ","
          when 189 then "-"
          else
            ""
    else
      String.fromCharCode(e.keyCode)

  animateCursor: (layer, cursor) ->
    flashTime = 0
    new Kinetic.Animation((frame) =>
      if frame.time > (flashTime + 500)
        flashTime = frame.time
        if cursor.getOpacity() == 1
          cursor.setOpacity(0)
        else
          cursor.setOpacity(1)
        layer.draw()
    , layer)


  render: (context, layer) ->
    textRect = new Kinetic.Rect({x: @spec.x, y: @spec.y, width: @spec.width, height: @spec.height, fill: @spec.fill, cornerRadius: 4, lineJoin: "round", stroke: @spec.stroke, strokeWidth: @spec.strokeWidth})
    textContent = @spec.content


    fsize = .85 * @spec.height

    text = new Kinetic.Text({text: @spec.content, x: @spec.x + 2, y: @spec.y - 5, height: @spec.height, fontSize: fsize, fill: "black", padding: 10, align: "left"})
    cursor = new Kinetic.Rect({x: text.getX() + text.getWidth() - 7, y: @spec.y + 5, width: 1.5, height: text.getHeight() - 10, fill: "black"})

    enterPressed = false
    keyStream = context.keydownStream()
    keyStream.takeWhile((x) =>
      enterPressed is false and not @stopped).onValue((event) =>
      if event.keyCode == 13
        ## Enter Key, Submit Text
        enterPressed = true

      else if event.keyCode == 8
        ## Backspace

        textContent = textContent.slice(0, -1)
        text.setText(textContent)
        cursor.setX(text.getX() + text.getWidth() - 7)
        layer.draw()
      else if text.getWidth() > textRect.getWidth()
        return
      else
        char = @getChar(event)
        textContent += char

        text.setText(textContent)
        cursor.setX(text.getX() + text.getWidth() - 7)
        layer.draw())

    cursorBlink = @animateCursor(layer, cursor)
    cursorBlink.start()

    group = new Kinetic.Group({})
    group.add(textRect)
    group.add(cursor)
    group.add(text)
    layer.add(group)

exports.TextInput = TextInput
