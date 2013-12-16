html = require("./html")


class HtmlButton extends html.HtmlStimulus

  defaults:
    label: "Next", class: ""

  constructor: (spec = {}) ->
    super(spec)

    @el.addClass("ui button")
    @el.addClass(@spec.class)
    @el.append(@spec.label)
    @positionElement(@el)


exports.HtmlButton = HtmlButton