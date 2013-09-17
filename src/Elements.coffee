Psy = require("./PsyCloud")
Bacon = require("./lib/Bacon").Bacon
_ = require('lodash')
Q = require("q")


if window?.performance.now
  console.log("Using high performance timer")
  getTimestamp = -> window.performance.now()
else if window?.performance.webkitNow
  console.log("Using webkit high performance timer")
  getTimestamp = -> window.performance.webkitNow()
else
  console.log("Using low performance timer");
  getTimestamp = -> new Date().getTime()


doTimer = (length, resolution, oninstance, oncomplete) ->
  instance = ->
    if count++ is steps
      oncomplete steps, count
    else
      oninstance steps, count
      diff = (getTimeStamp() - start) - (count * speed)
      window.setTimeout instance, (speed - diff)
  steps = (length / 100) * (resolution / 10)
  speed = length / steps
  count = 0
  start = getTimeStamp()
  window.setTimeout instance, speed



exports.Response =
class Response
  @delay = (ms, func) -> setTimeout func, ms


exports.Timeout =
class Timeout extends Response

  constructor: (spec = {}) ->
    @spec = _.defaults(spec, { duration: 2000 } )

  activate: (context) ->
    console.log("activating Timeout", @spec.duration)
    Q.delay(@spec.duration)

exports.Prompt =
class Prompt extends Response
  constructor: (@spec = {}) ->
    @spec = _.defaults(@spec, { title: "", delay: 0, defaultValue: "" })

  activate: (context) ->
    console.log("Prompting: ", @title)
    deferred = Q.defer()
    #if @delay > 0
    promise = Q.delay(@spec.delay)
    console.log("got promise")
    promise.then((f) =>
      result = window.prompt(@spec.title, @spec.defaultValue)
      deferred.resolve(result))
    deferred.promise

exports.TypedResponse =
class TypedResponse
  constructor: (@spec = {}) ->
    @spec = _.defaults(@spec, { left: 250, top: 250, defaultValue: "" })

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



exports.MousepressResponse =
class MousepressResponse extends Response
  constructor: ->

  activate: (context) ->
    deferred = Q.defer()
    mouse = context.mousepressStream()
    mouse.stream.take(1).onValue((event) =>
                               mouse.stop()
                               deferred.resolve(event))
    deferred.promise


exports.KeypressResponse =
class KeypressResponse extends Response
  constructor: (@spec = {}) ->
    @spec = _.defaults(@spec, { keys: ['n', 'm'], correct: ['n'], timeout: 3000} )

  activate: (context) ->
    deferred = Q.defer()
    keyStream = context.keypressStream()
    keyStream.filter((event) =>
      char = String.fromCharCode(event.keyCode)
      console.log(char)
      console.log(event.keyCode)
      _.contains(@spec.keys, char)).take(1).onValue((filtered) =>
                                Acc = _.contains(@spec.correct, String.fromCharCode(filtered.keyCode))
                                console.log("Acc", Acc)
                                context.logEvent("$ACC", Acc)

                                deferred.resolve(event))

    deferred.promise

exports.SpaceKeyResponse =
class SpaceKeyResponse extends Response
  constructor: (@spec = {}) ->

  activate: (context) ->

    deferred = Q.defer()
    keyStream = context.keypressStream()
    keyStream.filter((event) =>
      char = String.fromCharCode(event.keyCode)
      console.log(char)
      console.log(event.keyCode)
      event.keyCode == 32).take(1).onValue((event) => deferred.resolve(event))

    deferred.promise

exports.FirstResponse =
class FirstResponse extends Response
  constructor: (@responses) ->

  activate: (context) ->
    deferred = Q.defer()

    promises = _.map(@responses, (resp) => resp.activate(context).then(=> deferred.resolve(resp)))
    deferred.promise

exports.ClickResponse =
class ClickResponse extends Response
  constructor: (@id) ->

  activate: (context) ->
    element = context.stage.get("#" + @id)

    if not element
      throw "cannot find element with id" + @id

    deferred = Q.defer()
    element.on "click", (ev) =>
      deferred.resolve(ev)

    deferred.promise


exports.Stimulus =
class Stimulus
  spec: { }

  overlay: false

  constructor: ->

  render: (context, layer) ->

  stop: ->

  id: -> @spec.id or -9999


exports.Sound =
class Sound

  constructor: (@url) ->
    @sound = new buzz.sound(@url)

  render: (context) ->
    @sound.play()


exports.Picture =
class Picture extends Stimulus
  constructor: (spec = {} ) ->
    @spec = _.defaults(spec, { url: "http://www.html5canvastutorials.com/demos/assets/yoda.jpg", x:0, y: 0 })
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

  constructor: (@stims) ->
    @overlay = true

  render: (context, layer) ->
    for stim in @stims
      stim.render(context, layer)


exports.Background =
class Background extends Stimulus

  constructor:  (@stims=[], @fill= "white") ->
    @background = new Kinetic.Rect({x:0, y:0, width:0, height:0, fill: @fill})

  render: (context, layer) ->
    @background = new Kinetic.Rect({
      x: 0,
      y: 0,
      width: context.width(),
      height: context.height(),
      name: 'background'
      fill: @fill
    })

    console.log("rendering background")
    layer.add(@background)

    for stim in @stims
      console.log("rendering stim background")
      stim.render(context, layer)



exports.Sequence =
class Sequence extends Stimulus
  stopped: false

  constructor: (@stims, @soa, @clear=true) ->
    if (@soa.length != @stims.length)
      @soa = Psy.repLen(@soa, @stims.length)

    @onsets = for i in [0...@soa.length]
      _.reduce(@soa[0..i], (x, acc) -> x + acc)



  render: (context, layer) ->
    _.forEach([0...@stims.length], (i) =>
      ev = new Timeout({duration: @onsets[i]})
      stim = @stims[i]

      ev.activate(context).then(=>
        if not @stopped
          if @clear
            context.clearContent()
          stim.render(context)
          layer.draw()))

  stop: ->
    console.log("stopping Sequence!")
    @stopped = true


exports.Blank =
class Blank extends Stimulus

  constructor: (spec={}) ->
    @spec = _.defaults(spec, { fill: "white" })


  render: (context, layer) ->
    blank = new Kinetic.Rect({ x: 0, y: 0, width: context.width(), height: context.height(), fill: @spec.fill })
    layer.add(blank)


exports.Clear =
class Clear extends Stimulus
  constructor: (@spec = {}) ->

  render: (context, layer) ->
    context.clearContent(true)

exports.Rectangle =
class Rectangle extends Stimulus
  constructor: (spec = {}) ->
    @spec = _.defaults(spec, { x: 0, y: 0, width: 100, height: 100, fill: 'red'})
    @spec = _.omit(@spec, (value, key) -> not value)


  render: (context, layer) ->
    rect = new Kinetic.Rect({ x: @spec.x, y: @spec.y, width: @spec.width, height: @spec.height, fill: @spec.fill, stroke: @spec.stroke, strokeWidth: @spec.strokeWidth })
    layer.add(rect)


exports.Circle =
class Circle extends Stimulus
    constructor: (spec = {}) ->
      @spec = _.defaults(spec, { x: 100, y: 100, radius: 50, fill: 'red'})

    render: (context, layer) ->
      circ = new Kinetic.Circle({ x: @spec.x, y: @spec.y, radius: @spec.radius, fill: @spec.fill, stroke: @spec.stroke, strokeWidth: @spec.strokeWidth })
      layer.add(circ)
      #context.contentLayer.draw()





exports.FixationCross =
class FixationCross extends Stimulus
  constructor: (spec = {}) ->
    @spec = _.defaults(spec, { strokeWidth: 8, length: 150, fill: 'black'})

  render: (context, layer) ->

    x = context.width()/2
    y = context.height()/2

    horz = new Kinetic.Rect({ x: x - @spec.length/2, y: y, width: @spec.length, height: @spec.strokeWidth, fill: @spec.fill })
    vert = new Kinetic.Rect({ x: x - @spec.strokeWidth/2, y: y - @spec.length/2 + @spec.strokeWidth/2, width: @spec.strokeWidth, height: @spec.length, fill: @spec.fill })
    group = new Kinetic.Group()
    group.add(horz)
    group.add(vert)

    layer.add(group)


exports.CanvasBorder =
class CanvasBorder extends Stimulus
  constructor: (spec = {}) ->
    @spec = _.defaults(spec, { strokeWidth: 5, stroke: "black" })

  render: (context, layer) ->
    border = new Kinetic.Rect({ x: 0, y: 0, width: context.width(), height: context.height(), strokeWidth: @spec.strokeWidth, stroke: @spec.stroke })
    layer.add(border)


exports.StartButton =
class StartButton extends Stimulus
  constructor: (spec = {}) ->

    @spec = _.defaults(spec, { width: 150, height: 75 })

  render: (context, layer) ->

    xcenter = context.width()/2
    ycenter = context.height()/2

    group = new Kinetic.Group({id: @spec.id})

    text = new Kinetic.Text({text: "Start", x: xcenter - @spec.width/2, y: ycenter - @spec.height/2, width: @spec.width, height: @spec.height, fontSize: 30, fill: "white", fontFamily: "Arial", align: "center", padding: 20})
    button = new Kinetic.Rect({x: xcenter - @spec.width/2, y: ycenter - text.getHeight()/2, width: @spec.width, height: text.getHeight(), fill: "black", cornerRadius: 10,  stroke: "LightSteelBlue", strokeWidth: 5})
    group.add(button)
    group.add(text)

    layer.add(group)


position = (pos, offx, offy, width, height, xy) ->
  switch pos
    when "center" then [offx + width * .5, offy + height * .5]
    when "center-left" then [offx + width * 1/6, offy + height * .5]
    when "center-right" then [offx + width * 5/6, offy + height * .5]
    when "top-left" then [offx + width * 1/6, offy + height * 1/6]
    when "top-right" then [offx + width * 5/6, offy + height * 1/6]
    when "top-center" then [offx + width * .5, offy + height * 1/6]
    when "bottom-left" then [offx + width * 1/6, offy + height * 5/6]
    when "bottom-right" then [offx + width * 5/6, offy + height * 5/6]
    when "bottom-center" then [offx + width * .5, offy + height * 5/6]

    else xy

exports.Text =
class Text extends Stimulus
  constructor: (spec = {}) ->
    @spec = _.defaults(spec, { content: "Text", x: 100, y: 100, fill: "black", fontSize: 50, fontFamily: "Arial", lineHeight: 1, textAlign: "center", position: null} )


  render: (context, layer) ->
    #console.log("trial meta ", context.currentTrial.meta)

    text = new Kinetic.Text({
      x: @spec.x,
      y: @spec.y,
      text: @spec.content,
      fontSize: @spec.fontSize,
      fontFamily: @spec.fontFamily,
      fill: @spec.fill
      listening: false
    })

    if @spec.position
      xy = position(@spec.position, -text.getWidth()/2, -text.getHeight()/2, context.width(), context.height(), [@spec.x, @spec.y])
      text.setPosition({x:xy[0], y:xy[1]})

    layer.add(text)





exports.KineticContext =
class KineticContext extends Psy.ExperimentContext

  constructor: (@stage) ->
    @contentLayer = new Kinetic.Layer({clearBeforeDraw: true})
    @backgroundLayer = new Kinetic.Layer({clearBeforeDraw: true})
    @background = new Background([], fill: "white")



    @stage.add(@backgroundLayer)
    @stage.add(@contentLayer)


    @backgroundLayer.on("click", -> console.log("background layer click"))

    @stage.on("mousedown", -> console.log("stage mouse down"))
    @stage.getContent().addEventListener('mousedown', () -> console.log("stage dom click"))

  setBackground: (newBackground) ->
    @background = newBackground
    @backgroundLayer.removeChildren()
    @background.render(this, @backgroundLayer)

  drawBackground: -> @backgroundLayer.draw()

  clearBackground: ->
    @backgroundLayer.removeChildren()

  clearContent: (draw=false) ->
    @contentLayer.removeChildren()
    if draw

      @draw()



  draw: ->
    @backgroundLayer.draw()
    @contentLayer.draw()
    #@stage.draw()


  width: -> @stage.getWidth()

  height: -> @stage.getHeight()

  offsetX: -> @stage.getOffsetX()

  offsetY: -> @stage.getOffsetY()

  keydownStream: -> Bacon.fromEventTarget(window, "keydown")

  keypressStream: -> Bacon.fromEventTarget(window, "keypress")

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
  makeStimulus: (name, params) ->
    switch name
      when "FixationCross" then new FixationCross(params)
      when "Text" then new Text(params)
      else throw "No Stimulus type of name #{name}"
  makeResponse: (name, params) ->
    switch name
      when "KeyPressed" then new KeypressResponse(params)
      when "Timeout" then new Timeout(params)
      else throw "No Response type of name #{name}"

  makeEvent: (stim, response) -> new Psy.Event(stim, response)


x = new Sequence(['a', 'b', 'c'], [0,1000,1500])
