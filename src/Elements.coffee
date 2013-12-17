
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