Module = require("../module").Module
_ = require('lodash')

Canvas = require("./canvas/canvas").Canvas
Html = require("./html/html").Html


class ComponentFactory extends Module

  constructor: (@context) ->

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
  constructor: ->
    @registry = _.merge(Canvas, Html)

  make: (name, params) ->




for key, value of (new DefaultComponentFactory().registry)
  console.log(key, value)


