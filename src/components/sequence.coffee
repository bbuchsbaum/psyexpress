Stimulus = require("../stimresp").Stimulus
Timeout = require("./timeout").Timeout
Q = require("q")
utils = require("./utils")


class Sequence extends Stimulus

  constructor: (@stims, @soa, @clear = true, @times = 1) ->
    super({})
    if (@soa.length != @stims.length)
      @soa = utils.repLen(@soa, @stims.length)

    @onsets = for i in [0...@soa.length]
      _.reduce(@soa[0..i], (x, acc) ->
        x + acc)


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
        if i == @stims.length - 1
          deferred.resolve(1)
      )
    )

    deferred.promise


  render: (context, layer) ->
    result = Q.resolve(0)
    for i in [0...@times]
      result = result.then(=>
        @genseq(context, layer))
    result.then(=>
      context.clearContent()
    )


exports.Sequence = Sequence