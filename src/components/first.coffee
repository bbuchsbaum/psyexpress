
Q = require("q")
Response = require("../stimresp").Response


class First extends Response
  constructor: (@responses) ->
    super({})

  activate: (context) ->
    deferred = Q.defer()
    _.forEach(@responses, (resp) =>
      resp.activate(context).then(=>
        deferred.resolve(resp)))

    deferred.promise


exports.First = First