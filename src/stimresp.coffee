_ = require('lodash')
lay = require("./layout")
Module = require("./module").Module


exports.Stimulus =
class Stimulus extends Module

  defaults: {}


  constructor: (spec={}) ->
    @spec = _.defaults(spec, @defaults)
    @spec = _.omit(@spec, (value, key) -> not value)

    @name = @constructor.name

    if @spec?.id?
      @id = @spec.id
    else
      @id = _.uniqueId("stim_")

    @stopped = false

    @layout =  new lay.AbsoluteLayout()

    @overlay =  false

    @name = this.constructor.name


  computeCoordinates: (context, position) ->
    if position
      cpos = @layout.computePosition([context.width(), context.height()], position)
      cpos
    else if @spec.x and @spec.y
      [@spec.x, @spec.y]
    else [0,0]

  reset: -> @stopped = false

  render: (context, layer) ->

  stop: (context) -> @stopped = true

  #id: -> @spec.id or _.uniqueId()

exports.Response =
class Response extends Stimulus

  start: (context) -> @activate(context)

  activate: (context) ->