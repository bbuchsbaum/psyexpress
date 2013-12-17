Q = require("q")
Response = require("../stimresp").Response


class Click extends Response

  constructor: (@refid) ->
    super()

  activate: (context) ->

    ## should be able to handle Kinetic object or html element
    element = context.stage.get("#" + @refid)

    if not element
      throw new Error("cannot find element with id" + @refid)

    deferred = Q.defer()
    element.on "click", (ev) =>
      deferred.resolve(ev)

    deferred.promise

exports.Click = Click