Module = require("../module").Module
_ = require('lodash')

class ComponentFactory extends Module

  constructor: (@context)

  buildStimulus: (spec) ->
    stimType = _.keys(spec)[0]
    params = _.values(spec)[0]
    @makeStimulus(stimType, params)

  buildResponse: (spec) ->
    responseType = _.keys(spec)[0]
    params = _.values(spec)[0]
    @makeResponse(responseType, params)

  buildEvent: (spec) ->
    stimSpec = _.omit(spec, "Next")
    responseSpec = _.pick(spec, "Next")

    stim = @buildStimulus(stimSpec)
    response = @buildResponse(responseSpec.Next)
    @makeEvent(stim, response)

  make: (name, params) ->
    throw new Error("unimplemented")


  makeStimulus: (name, params) ->
    throw new Error("unimplemented")

  makeResponse: (name, params) ->
    throw new Error("unimplemented")

  makeEvent: (stim, response) ->
    throw new Error("unimplemented")

  makeLayout: (name, params) ->



exports.ComponentFactory = ComponentFactory

class DefaultComponentFactory extends ComponentFactory


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




