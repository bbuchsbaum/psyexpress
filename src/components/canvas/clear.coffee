
Stimulus = require("../../stimresp").Stimulus


class Clear extends Stimulus

  render: (context, layer) ->
    context.clearContent(true)


exports.Clear = Clear