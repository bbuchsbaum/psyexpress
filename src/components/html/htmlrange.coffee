html = require("./html")


class HtmlRange extends html.Stimulus

  defaults:
    min: 0, max: 100, value: 0, step: 1, height: 100, width: 300

  constructor: (spec = {}) ->
    super(spec)

    @input = $("""<input type='range'>""")
    @input.attr(
      min: @spec.min
      max: @spec.max
      value: @spec.value
      step: @spec.step
    )
    @input.css(
      width: @spec.width
    )
    @el.append(@input)


exports.HtmlRange = HtmlRange