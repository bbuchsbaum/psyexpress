
Q = require("q")
Response = require("../stimresp").Response


class Confirm extends Response

  defaults:
    message: "", delay: 0, defaultValue: "", theme: 'vex-theme-wireframe'

  activate: (context) ->
    console.log("activating confirm dialog")
    deferred = Q.defer()
    promise = Q.delay(@spec.delay)
    promise.then((f) =>
      console.log("rendering confirm dialog")
      vex.dialog.confirm
        message: @spec.message
        className: @spec.theme
        callback: (value) ->
          deferred.resolve(value)
    )

    deferred.promise

exports.Confirm = Confirm