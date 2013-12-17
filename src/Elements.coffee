
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
Background = require("./components/canvas/Background").Background

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




exports.MousePressResponse =
class MousePressResponse extends Response

  constructor: ->
    super({}, {})

  activate: (context) ->
    deferred = Q.defer()
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





exports.Sound =
class Sound

  constructor: (@url) ->
    @sound = new buzz.sound(@url)

  render: (context) ->
    @sound.play()




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




exports.Paragraph =
class Paragraph extends Stimulus
  constructor: (spec = {}) ->
    super(spec, { content: "", x: 50, y: 50, width: 600, fill: "black", fontSize: 18, fontFamily: "Arial", lineHeight: 1, textAlign: "center", position: null} )




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