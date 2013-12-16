
Psy = require("./psycloud")

Bacon = require("./lib/Bacon").Bacon
_ = require('lodash')
Q = require("q")
marked = require("marked")
utils = require("./utils")
lay = require("./layout")
Base = require("./stimresp")
Stimulus = Base.Stimulus
Response = Base.Response

{renderable, ul, li, input} = require('teacup')


Layout = lay.Layout
AbsoluteLayout = lay.AbsoluteLayout
GridLayout = lay.GridLayout




doTimer = utils.doTimer
disableBrowserBack = utils.disableBrowserBack
getTimestamp = utils.getTimeStamp



exports.Timeout =
class Timeout extends Response

  constructor: (spec = {}) ->
    super(spec, { duration: 2000 } )

    @oninstance = (steps, count) -> console.log(steps, count)

  activate: (context) ->
    deferred = Q.defer()

    doTimer(@spec.duration, (diff) => deferred.resolve({timeout: diff, requested: @spec.duration}))
    deferred.promise



exports.Prompt =
class Prompt extends Response
  constructor: (spec = {}) ->
    super(spec, { title: "", delay: 0, defaultValue: "" })

  activate: (context) ->
    deferred = Q.defer()
    promise = Q.delay(@spec.delay)
    promise.then((f) =>
      vex.dialog.prompt
        message: @spec.title
        placeholder: @spec.defaultValue
        className: 'vex-theme-wireframe'
        callback: (value) -> deferred.resolve(value)
    )

      #result = window.prompt(@spec.title, @spec.defaultValue)
      #deferred.resolve(result))
    deferred.promise

exports.Confirm =
  class Confirm extends Response
    constructor: (spec = {}) ->
      super(spec, { message: "", delay: 0, defaultValue: "" })

    activate: (context) ->
      deferred = Q.defer()
      promise = Q.delay(@spec.delay)
      promise.then((f) =>
        vex.dialog.confirm
          message: @spec.message
          className: 'vex-theme-wireframe'
          callback: (value) -> deferred.resolve(value)
      )

      #result = window.prompt(@spec.title, @spec.defaultValue)
      #deferred.resolve(result))
      deferred.promise


exports.TypedResponse =
class TypedResponse
  constructor: (spec = {}) ->
    super(spec,  { left: 250, top: 250, defaultValue: "" })

  activate: (context) ->
    deferred = Q.defer()

    enterPressed = false
    freeText = "____"
    text = new fabric.Text(freeText, { top: @spec.top, left: @spec.left, fontSize: 50, textAlign: "left" })
    context.canvas.add(text)
    xoffset = text.width/2

    cursor = new fabric.Line([@spec.left, @spec.top + text.height/2, @spec.left, @spec.top-(text.height/2)])
    context.canvas.add(cursor)

    keyStream = context.keypressStream()
    keyStream.takeWhile((x) => enterPressed is false).onValue((event) =>

      if event.keyCode == 13
        enterPressed = true
        deferred.resolve(freeText)
      else
        char = String.fromCharCode(event.keyCode)
        freeText = freeText + char
        text.setText(freeText)
        text.set("left": @spec.left + (text.width/2 - xoffset))
        console.log(text.width)
        console.log(text.height)
        #console.log(text.getCenterPoint())
        #console.log(text.getBoundingRect())
        context.canvas.renderAll())


    deferred.promise



exports.MousePressResponse =
class MousePressResponse extends Response

  constructor: ->
    super({}, {})

  activate: (context) ->
    deferred = Q.de fer()
    mouse = context.mousepressStream()
    mouse.stream.take(1).onValue((event) =>
                               mouse.stop()
                               deferred.resolve(event))
    deferred.promise


exports.KeyPressResponse =
class KeyPressResponse extends Response


  constructor: (spec = {}) ->
    super(spec, { keys: ['n', 'm'], correct: ['n'], timeout: 3000} )

    @name =  "KeyPress"

  activate: (context) ->
    @startTime = getTimestamp()
    myname = @name
    deferred = Q.defer()
    keyStream = context.keypressStream()
    keyStream.filter((event) =>
      char = String.fromCharCode(event.keyCode)
      _.contains(@spec.keys, char)).take(1).onValue((filtered) =>
                                Acc = _.contains(@spec.correct, String.fromCharCode(filtered.keyCode))
                                timestamp = getTimestamp()
                                resp =
                                  name: myname
                                  id: @id
                                  KeyTime: timestamp
                                  RT: timestamp - @startTime
                                  Accuracy: Acc
                                  KeyChar: String.fromCharCode(filtered.keyCode)

                                context.pushData(resp)

                                context.logEvent("KeyPress", getTimestamp())
                                context.logEvent("$ACC", Acc)
                                console.log("resolving keypress")

                                deferred.resolve(resp))

    deferred.promise

exports.SpaceKeyResponse =
class SpaceKeyResponse extends Response
  constructor: (spec = {}) ->
    super(spec, {})

  activate: (context) ->

    deferred = Q.defer()
    keyStream = context.keypressStream()
    keyStream.filter((event) =>
      char = String.fromCharCode(event.keyCode)
      event.keyCode == 32).take(1).onValue((event) =>
        context.logEvent("SpaceKey", getTimestamp())
        deferred.resolve(event))

    deferred.promise

exports.FirstResponse =
class FirstResponse extends Response
  constructor: (@responses) ->
    super({}, {})

  activate: (context) ->
    deferred = Q.defer()
    promises = _.map(@responses, (resp) => resp.activate(context).then(=> deferred.resolve(resp)))
    deferred.promise

exports.ClickResponse =
class ClickResponse extends Response
  constructor: (@refid) ->

  activate: (context) ->
    element = context.stage.get("#" + @refid)

    if not element
      throw "cannot find element with id" + @refid

    deferred = Q.defer()
    element.on "click", (ev) =>
      context.logEvent("Click", getTimestamp())
      deferred.resolve(ev)

    deferred.promise


exports.GridLines =
class GridLines extends Stimulus
  constructor: (spec = {}) ->
    super(spec, { x: 0, y: 0, rows: 3, cols: 3, stroke: "black", strokeWidth: 2})

  render: (context, layer) ->
    for i in [0..@spec.rows]
      y = @spec.y + (i * context.height()/@spec.rows)
      line = new Kinetic.Line({
        points: [@spec.x, y, @spec.x + context.width(), y]
        stroke: @spec.stroke
        strokeWidth: @spec.strokeWidth
        dashArray: @spec.dashArray
      })

      layer.add(line)

    for i in [0..@spec.cols]
      x = @spec.x + (i * context.width()/@spec.cols)
      line = new Kinetic.Line({
        points: [x, @spec.y, x, @spec.y + context.height()]
        stroke: @spec.stroke
        strokeWidth: @spec.strokeWidth
        dashArray: @spec.dashArray
      })

      layer.add(line)




exports.TextInput =
class TextInput extends Stimulus
  constructor: (spec = {}) ->
    disableBrowserBack()
    super(spec, { x: 100, y: 100, width: 200, height: 40, defaultValue: "", fill: "#FAF5E6", stroke: "#0099FF", strokeWidth: 1, content: "" })

  getChar: (e) ->
    # key is not shift
    if e.keyCode!=16
      # key is a letter
      if e.keyCode >= 65 && e.keyCode <= 90
        if e.shiftKey
          String.fromCharCode(e.keyCode)
        else
          String.fromCharCode(e.keyCode + 32)
      else if e.keyCode >= 48 && e.keyCode <=57
        String.fromCharCode(e.keyCode)
      else
        #console.log("key code is",e.keyCode)
        switch e.keyCode
          when 186 then ";"
          when 187 then "="
          when 188 then ","
          when 189 then "-"
          else ""
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


    fsize =  .85 * @spec.height

    text = new Kinetic.Text({text: @spec.content, x: @spec.x+2, y: @spec.y - 5, height: @spec.height, fontSize: fsize, fill: "black", padding: 10, align: "left"})
    cursor = new Kinetic.Rect({x: text.getX() + text.getWidth() - 7, y: @spec.y + 5, width: 1.5, height: text.getHeight() - 10, fill: "black"})

    enterPressed = false
    keyStream = context.keydownStream()
    keyStream.takeWhile((x) => enterPressed is false and not @stopped).onValue((event) =>

      if event.keyCode == 13
        ## Enter Key, Submit Text
        enterPressed = true
        #deferred.resolve(freeText)
      else if event.keyCode == 8
        ## Backspace
        #console.log("delete key")
        textContent = textContent.slice(0, - 1)
        text.setText(textContent)
        cursor.setX(text.getX() + text.getWidth() - 7)
        layer.draw()
      else if text.getWidth() > textRect.getWidth()
        return
      else
        char = @getChar(event)
        #console.log("char is", char)
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


exports.Sound =
class Sound

  constructor: (@url) ->
    @sound = new buzz.sound(@url)

  render: (context) ->
    @sound.play()


exports.Picture =
class Picture extends Stimulus
  constructor: (spec = {} ) ->
    super(spec, { url: "http://www.html5canvastutorials.com/demos/assets/yoda.jpg", x:0, y: 0 })
    @imageObj = new Image()
    @image = null

    @imageObj.onload = =>

      @image = new Kinetic.Image({
        x: @spec.x,
        y: @spec.y,
        image: @imageObj,
        width: @spec.width or @imageObj.width,
        height: @spec.height or @imageObj.height
      })

    @imageObj.src = @spec.url



  render: (context, layer) ->
    layer.add(@image)
    #context.contentLayer.draw()




exports.Group =
class Group extends Stimulus

  constructor: (@stims, layout) ->
    super({}, {})
    #@overlay = true
    if layout
      @layout = layout
      for stim in @stims
        stim.layout = layout
        #stim.overlay=true


  render: (context, layer) ->
    console.log("rendering group")
    for stim in @stims
      stim.render(context, layer)

# VerticalGroup lays out stimuli from top to bottom


exports.Background =
class Background extends Stimulus

  constructor:  (@stims=[], @fill= "white") ->
    super({}, {})

  render: (context, layer) ->
    background = new Kinetic.Rect({
      x: 0,
      y: 0,
      width: context.width(),
      height: context.height(),
      name: 'background'
      fill: @fill
    })


    layer.add(background)

    for stim in @stims
      stim.render(context, layer)


exports.Sequence =
class Sequence extends Stimulus

  constructor: (@stims, @soa, @clear=true, @times=1) ->
    super({}, {})
    if (@soa.length != @stims.length)
      @soa = utils.repLen(@soa, @stims.length)

    @onsets = for i in [0...@soa.length]
      _.reduce(@soa[0..i], (x, acc) -> x + acc)


  genseq: (context, layer) ->
    deferred = Q.defer()
    _.forEach([0...@stims.length], (i) =>
      ev = new Timeout({duration: @onsets[i]})
      stim = @stims[i]

      ev.activate(context).then(=>
        if not @stopped
          if @clear
            context.clearContent()

          stim.render(context, layer)
          context.draw()
        if i == @stims.length-1
          deferred.resolve(1)
      )
    )

    deferred.promise


  render: (context, layer) ->
    result = Q.resolve(0)
    for i in [0...@times]
      result = result.then(=> @genseq(context,layer))
    result.then(=>
      context.clearContent()
    )

  #stop: (context) -> @stopped = true


exports.Blank =
class Blank extends Stimulus

  constructor: (spec={}) ->
    super(spec, { fill: "white" })


  render: (context, layer) ->
    blank = new Kinetic.Rect({ x: 0, y: 0, width: context.width(), height: context.height(), fill: @spec.fill })
    layer.add(blank)


exports.Clear =
class Clear extends Stimulus
  constructor: (spec = {}) ->
    super(spec, {})

  render: (context, layer) ->
    context.clearContent(true)


exports.Rectangle =
class Rectangle extends Stimulus
  constructor: (spec = {}) ->
    super(spec, { x: 0, y: 0, width: 100, height: 100, fill: 'red'} )
    @spec = _.omit(@spec, (value, key) -> not value)

    if @spec.layout?
      @layout = @spec.layout

  render: (context, layer) ->
    console.log("rendering rect")
    console.log("spec is", @spec)
    console.log("has computeCoordinates", @computeCoordinates)
    console.log("position", @spec.position)
    coords = @computeCoordinates(context, @spec.position)
    console.log("coords", coords)
    rect = new Kinetic.Rect({ x: coords[0], y: coords[1], width: @spec.width, height: @spec.height, fill: @spec.fill, stroke: @spec.stroke, strokeWidth: @spec.strokeWidth })
    layer.add(rect)


exports.Circle =
class Circle extends Stimulus
    constructor: (spec = {}) ->
      super(spec, { x: 100, y: 100, radius: 50, fill: 'red', opacity: 1})

    render: (context, layer) ->
      circ = new Kinetic.Circle({ x: @spec.x, y: @spec.y, radius: @spec.radius, fill: @spec.fill, stroke: @spec.stroke, strokeWidth: @spec.strokeWidth, opacity: @spec.opacity })
      layer.add(circ)
      #context.contentLayer.draw()






exports.CanvasBorder =
class CanvasBorder extends Stimulus
  constructor: (spec = {}) ->
    super(spec, { strokeWidth: 5, stroke: "black" })

  render: (context, layer) ->
    border = new Kinetic.Rect({ x: 0, y: 0, width: context.width(), height: context.height(), strokeWidth: @spec.strokeWidth, stroke: @spec.stroke })
    layer.add(border)


exports.StartButton =
class StartButton extends Stimulus
  constructor: (spec = {}) ->
    super(spec, { width: 150, height: 75 })

  render: (context, layer) ->

    xcenter = context.width()/2
    ycenter = context.height()/2

    group = new Kinetic.Group({id: @spec.id})

    text = new Kinetic.Text({text: "Start", x: xcenter - @spec.width/2, y: ycenter - @spec.height/2, width: @spec.width, height: @spec.height, fontSize: 30, fill: "white", fontFamily: "Arial", align: "center", padding: 20})
    button = new Kinetic.Rect({x: xcenter - @spec.width/2, y: ycenter - text.getHeight()/2, width: @spec.width, height: text.getHeight(), fill: "black", cornerRadius: 10,  stroke: "LightSteelBlue", strokeWidth: 5})
    group.add(button)
    group.add(text)

    layer.add(group)




exports.Paragraph =
class Paragraph extends Stimulus
  constructor: (spec = {}) ->
    super(spec, { content: "", x: 50, y: 50, width: 600, fill: "black", fontSize: 18, fontFamily: "Arial", lineHeight: 1, textAlign: "center", position: null} )




exports.Page =
class Page extends Stimulus
  constructor: (spec={}) ->
    super(spec, {html: "<div>HTML Page</div>"})
    @html = @spec.html

  render: (context, layer) ->
    context.appendHtml(@html)



exports.HtmlRange =
  class HtmlRange extends Stimulus
    constructor: (spec={}) ->
      super(spec, {min: 0, max: 100, value: 0, step: 1, height: 100, width: 300})

      @html = $("""<div></div>""")
      @input = $("""<input type='range'>""")
      @input.attr(
        min: @spec.min
        max: @spec.max
        value: @spec.value
        step: @spec.step
      )
      @input.css(
        width: @spec.width
      )
      @html.append(@input)

    render: (context, layer) ->
      context.appendHtml(@html)




exports.MultipleChoice =
class MultipleChoice extends Stimulus
  constructor: (spec={}) ->
    super(spec, { question: "What is your name?", options: ["Bill", "John", "Fred"], x: 10, y: 10, fill: "black", fontSize: 24, fontFamily: "Arial", textAlign: "center", position: null})

  render: (context, layer) ->
    questionText = new Kinetic.Text({
      x: @spec.x
      y: @spec.y
      text: @spec.question
      fontSize: @spec.fontSize
      fontFamily: @spec.fontFamily
      fill: @spec.fill
    })

    layer.add(questionText)

    for i in [0...@spec.options.length]
      choice = new Kinetic.Text({
        x: @spec.x + 5
        y: questionText.getHeight() * (i+1) + 30
        text: (i+1) + ") " + @spec.options[i]
        fontSize: @spec.fontSize
        fontFamily: @spec.fontFamily
        fill: @spec.fill
        padding: 20
        align: 'left'
      })

      layer.add(choice)


exports.KineticContext =
class KineticContext extends Psy.ExperimentContext

  constructor: (@stage) ->
    super(new KineticStimFactory())
    @contentLayer = new Kinetic.Layer({clearBeforeDraw: true})
    @backgroundLayer = new Kinetic.Layer({clearBeforeDraw: true})
    @background = new Background([], fill: "white")

    @stage.add(@backgroundLayer)
    @stage.add(@contentLayer)

    #@backgroundLayer.on("click", -> console.log("background layer click"))
    #@stage.on("mousedown", -> console.log("stage mouse down"))
    #@stage.getContent().addEventListener('mousedown', () -> console.log("stage dom click"))

    @insertHTMLDiv()



  insertHTMLDiv: ->
    super
    $(".kineticjs-content").css("position", "absolute")


  setBackground: (newBackground) ->
    @background = newBackground
    @backgroundLayer.removeChildren()
    @background.render(this, @backgroundLayer)

  drawBackground: -> @backgroundLayer.draw()

  clearBackground: ->
    @backgroundLayer.removeChildren()

  clearContent: (draw=false) ->
    #@hideHtml()
    @clearHtml()
    @backgroundLayer.draw()
    @contentLayer.removeChildren()
    if draw
      @draw()


  draw: ->
    $('#container' ).focus()
    #@background.render(this, @backgroundLayer)
    @contentLayer.draw()
    #@stage.draw()


  width: -> @stage.getWidth()

  height: -> @stage.getHeight()

  offsetX: -> @stage.getOffsetX()

  offsetY: -> @stage.getOffsetY()


  keydownStream: -> $("body").asEventStream("keydown")

  keypressStream: -> $("body").asEventStream("keypress")

  mousepressStream: ->
    class MouseBus
      constructor: () ->
        @stream = new Bacon.Bus()

        @handler = (x) =>
          @stream.push(x)

        @stage.on("mousedown", @handler)
        #@eventLayer.on('mousedown', @handler)
        #@stage.getContent().addEventListener('mousedown', @handler)

      stop: ->
        #@stage.getContent().removeEventListener("mousedown", @handler)
        #@eventLayer.off('mousedown', @handler)
        @stage.off("mousedown", @handler)
        @stream.end()


    #new MouseBus(@eventLayer)
    new MouseBus()


exports.KineticStimFactory =
class KineticStimFactory extends Psy.StimFactory


  makeLayout: (name, params, context) ->
    switch name
      when "Grid"
        new GridLayout(params[0], params[1], {x: 0, y: 0, width: context.width(), height: context.height()})

  makeInstructions: (spec) ->
    new Instructions(spec)


  makeStimulus: (name, params, context) ->

    callee = arguments.callee

    switch name
      when "FixationCross" then new FixationCross(params)
      when "Clear" then new Clear(params)
      when "Group"
        names = _.map(params.stims, (stim) -> _.keys(stim)[0])
        props = _.map(params.stims, (stim) -> _.values(stim)[0])
        stims = for i in [0...names.length]
          callee(names[i], props[i])

        layoutName = _.keys(params.layout)[0]
        layoutParams = _.values(params.layout)[0]

        new Group(stims, @makeLayout(layoutName, layoutParams, context))

      when "Instructions" then new Instructions(params)
      when "Rectangle" then new Rectangle(params)
      when "Text" then new Text(params)
      when "HtmlIcon" then new HtmlIcon(params)

      else throw "No Stimulus type of name #{name}"

  makeResponse: (name, params, context) ->
    console.log("making response", name)
    switch name
      when "KeyPress" then new KeyPressResponse(params)
      when "SpaceKey" then new SpaceKeyResponse(params)
      when "Timeout" then new Timeout(params)
      else throw new Error("No Response type of name #{name}")

  makeEvent: (stim, response) -> new Psy.Event(stim, response)



#x = new Timeout({duration: 22})
#prom = x.activate()
#prom.then( (resp) ->
#  console.log("resp", resp)
#)

#console.log(new Response().id)