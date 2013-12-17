utils = require("../utils")
Q = require("q")
Response = require("../stimresp").Response


class Timeout extends Response

  defaults:
    duration: 1000

  activate: (context) ->
    deferred = Q.defer()

    utils.doTimer(@spec.duration, (diff) =>
      deferred.resolve({timeout: diff, requested: @spec.duration}))
    deferred.promise


exports.Timeout = Timeout