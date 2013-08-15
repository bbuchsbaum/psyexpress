Psy = require("./Psytools")
Bacon = require("./lib/Bacon").Bacon
_ = require('lodash')
Q = require("q")

doTimer = (length, resolution, oninstance, oncomplete) ->
  instance = ->
    if count++ is steps
      oncomplete steps, count
    else
      oninstance steps, count
      diff = (new Date().getTime() - start) - (count * speed)
      window.setTimeout instance, (speed - diff)
  steps = (length / 100) * (resolution / 10)
  speed = length / steps
  count = 0
  start = new Date().getTime()
  window.setTimeout instance, speed



exports.Response =
class Response
  @delay = (ms, func) -> setTimeout func, ms


exports.Timeout =
class Timeout extends Response

  constructor: (@duration) ->

  activate: (context) ->
    Q.delay(@duration)

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
      console.log("got key", event)
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
  constructor: (@keyset) ->
    console.log("keyset is ", @keyset)

  activate: (context)   ->
    console.log("activated")
    deferred = Q.defer()
    keyStream = context.keypressStream()
    keyStream.filter((event) =>
      char = String.fromCharCode(event.keyCode)
      console.log("char", char)
      console.log("keyset", @keyset)
      _.contains(@keyset, char)).take(1).onValue((event) =>
                                console.log("resolving event", event.keyCode)
                                deferred.resolve(event))

    deferred.promise



exports.Stimulus =
class Stimulus

  render: (context) ->


exports.Sound =
class Sound

  constructor: (@url) ->
    console.log("loading ", @url)
    #@sound = new Howl({
    #  urls: @url
    #})
    @sound = new buzz.sound(@url)



  render: (context) ->
    @sound.play()


exports.Blank =
class Blank extends Stimulus

  constructor: (@spec = {
    backgroundColor: 'rgb(125,0,125)'
  }) ->

  render: (context) ->
#    context.canvas.backgroundColor = @spec.backgroundColor
    context.canvas.renderAll()

exports.FixationCross =
class FixationCross extends Stimulus
  constructor: (@spec = {}) ->
    @spec = _.defaults(@spec, { strokeWidth: 6, length: 100, fill: 'black'})

  render: (context) ->

    x = context.width()/2
    y = context.height()/2

    horz = new Kinetic.Rect({ x: x - @spec.length/2, y: y, width: @spec.length, height: @spec.strokeWidth, fill: @spec.fill })
    vert = new Kinetic.Rect({ x: x - @spec.strokeWidth/2, y: y - @spec.length/2 + @spec.strokeWidth/2, width: @spec.strokeWidth, height: @spec.length, fill: @spec.fill })
    layer = new Kinetic.Layer()
    layer.add(horz)
    layer.add(vert)
    #horz.setListening(false)
    #vert.setListening(false)
    context.baseLayer.add(layer)
    #context.baseLayer.add(vert)
    context.baseLayer.draw()
    #layer.setListening(false)

exports.CanvasBorder =
class CanvasBorder extends Stimulus
  constructor: (@spec = {}) ->
    @spec = _.defaults(@spec, { strokeWidth: 5, stroke: "blue" })

  render: (context) ->
    console.log(context.width())
    console.log(context.height())
    border = new Kinetic.Rect({ x: 0, y: 0, width: context.width(), height: context.height(), strokeWidth: @spec.strokeWidth, stroke: @spec.stroke })
    context.baseLayer.add(border)
    context.baseLayer.draw()


exports.StartButton =
class StartButton extends Stimulus
  constructor: (@spec = {}) ->

    @spec = _.defaults(@spec, { width: 150, height: 75 })

  render: (context) ->

    xcenter = context.width()/2
    ycenter = context.height()/2
    text = new Kinetic.Text({text: "Start", x: xcenter - @spec.width/2, y: ycenter - @spec.height/2, width: @spec.width, height: @spec.height, fontSize: 30, fill: "white", fontFamily: "Arial", align: "center", padding: 20})
    button = new Kinetic.Rect({x: xcenter - @spec.width/2, y: ycenter - text.getHeight()/2, width: @spec.width, height: text.getHeight(), fill: "black", cornerRadius: 10,  stroke: "LightSteelBlue", strokeWidth: 5})

    layer = new Kinetic.Layer()
    layer.add(button)
    layer.add(text)
    layer.setListening(false)

    context.baseLayer.add(layer)
    context.baseLayer.draw()

exports.Text =
class Text extends Stimulus
  constructor: (@spec = {}) ->
    @spec = _.defaults(@spec, { content: "Text", x: 100, y: 100, fill: "black", fontSize: 50, fontFamily: "Arial", lineHeight: 1, textAlign: "center"} )

  render: (context) ->
    text = new Kinetic.Text({
      x: @spec.x,
      y: @spec.y,
      text: @spec.content,
      fontSize: @spec.fontSize,
      fontFamily: @spec.fontFamily,
      fill: @spec.fill
      listening: false
    })

    layer = new Kinetic.Layer()
    layer.add(text)
    layer.setListening(false)

    #text = new fabric.Text(@spec.content, { top: @spec.top, left: @spec.left, fontSize: @spec.fontSize, fill: @spec.fill, fontFamily: @spec.fontFamily, lineHeight: @spec.lineHeight, textAlign: @spec.textAlign})
    context.baseLayer.add(layer)
    ## don't necessarily want to redraw
    context.baseLayer.draw()


exports.Event =
class Event

  constructor: (@stimulus, @response) ->

  start: (context) ->
    console.log("starting event")
    ## clear layer
    context.baseLayer.removeChildren()
    context.eventLayer.moveToTop()
    console.log("rendering stimulus")

    ## display event
    @stimulus.render(context)
    console.log("activating response")

    ## activate response
    @response.activate(context)


exports.Trial =
class Trial
  constructor: (@events=[]) ->

  start: (context) ->
    farray = _.map(@events, (ev) => (=> ev.start(context)))
    result = Q.resolve(0)

    for fun in farray
      result = result.then(fun)
    result


exports.KineticContext =
class KineticContext extends Psy.ExperimentContext

  constructor: (@stage) ->
    @baseLayer = new Kinetic.Layer()
    @eventLayer = new Kinetic.Layer()

    @eventRect = new Kinetic.Rect({
      x: 0,
      y: 0,
      width: stage.getWidth(),
      height: stage.getHeight(),
      name: 'baseLayer'
    })

    @eventLayer.add(@eventRect)

    @stage.add(@baseLayer)
    @stage.add(@eventLayer)

    @baseLayer.on("mousedown", () -> console.log("base layer mouse down"))
    @eventRect.on("mousedown", () -> console.log("event rect mouse down"))
    @stage.on("mousedown", () -> console.log("stage mouse down"))
    @stage.getContent().addEventListener('mousedown', () -> console.log("stage dom click"))

  width: -> @stage.getWidth()

  height: -> @stage.getHeight()

  keydownStream: -> Bacon.fromEventTarget(window, "keydown")

  keypressStream: -> Bacon.fromEventTarget(window, "keypress")

  mousepressStream: ->
    class MouseBus
      constructor: (@eventLayer) ->
        @stream = new Bacon.Bus()

        @handler = (x) =>
          @stream.push(x)

        @eventLayer.on('mousedown', @handler)
        #@stage.getContent().addEventListener('mousedown', @handler)

      stop: ->
        #@stage.getContent().removeEventListener("mousedown", @handler)
        @eventLayer.off('mousedown', @handler)
        @stream.end()


    new MouseBus(@eventLayer)


