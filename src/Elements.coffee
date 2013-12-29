
#Psy = require("./psycloud")
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




exports.KineticStimFactory =
class KineticStimFactory #extends Psy.StimFactory

  constructor: ->
    console.log("making stim factory")


  makeLayout: (name, params, context) ->
    #switch name
    #  when "Grid"
    #    new GridLayout(params[0], params[1], {x: 0, y: 0, width: context.width(), height: context.height()})

  makeInstructions: (spec) ->
    #new Instructions(spec)


  makeStimulus: (name, params, context) ->

    #callee = arguments.callee

    #switch name
    #  when "FixationCross" then new FixationCross(params)
    #  when "Clear" then new Clear(params)
    #  when "Group"
    #    names = _.map(params.stims, (stim) -> _.keys(stim)[0])
    #    props = _.map(params.stims, (stim) -> _.values(stim)[0])
    #    stims = for i in [0...names.length]
    #      callee(names[i], props[i])
    ###
        layoutName = _.keys(params.layout)[0]
        layoutParams = _.values(params.layout)[0]

        new Group(stims, @makeLayout(layoutName, layoutParams, context))

      when "Instructions" then new Instructions(params)
      when "Rectangle" then new Rectangle(params)
      when "Text" then new Text(params)
      when "HtmlIcon" then new HtmlIcon(params)

      else throw "No Stimulus type of name #{name}"

  ###

  makeResponse: (name, params, context) ->
    ###console.log("making response", name)
    switch name
      when "KeyPress" then new KeyPressResponse(params)
      when "SpaceKey" then new SpaceKeyResponse(params)
      when "Timeout" then new Timeout(params)
      else throw new Error("No Response type of name #{name}")
    ###
  makeEvent: (stim, response) ->
    # new Psy.Event(stim, response)


