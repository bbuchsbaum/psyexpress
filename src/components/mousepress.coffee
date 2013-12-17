Q = require("q")
Response = require("../stimresp").Response

class MousePress extends Response

  activate: (context) ->
    deferred = Q.defer()
    mouse = context.mousepressStream()
    mouse.stream.take(1).onValue((event) =>
      mouse.stop()
      deferred.resolve(event))
    deferred.promise

exports.MousePress = MousePress