utils = require("../utils")
Q = require("q")

Response = require("../stimresp").Response



class Prompt extends Response

  defaults:
    title: "Prompt", delay: 0, defaultValue: "", theme: 'vex-theme-wireframe'


  activate: (context) ->
    deferred = Q.defer()
    promise = Q.delay(@spec.delay)
    promise.then((f) =>
      vex.dialog.prompt
        message: @spec.title
        placeholder: @spec.defaultValue
        className: 'vex-theme-wireframe'
        callback: (value) ->
          deferred.resolve(value)
    )


    deferred.promise


exports.Prompt = Prompt