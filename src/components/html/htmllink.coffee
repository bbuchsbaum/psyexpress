html = require("./html")

class HtmlLink extends html.HtmlStimulus
  defaults:
    label: "link"

  constructor: (spec = {}) ->
    super(spec)
    @html = $("""<a href='#'>#{@spec.label}</a>""")
    @el.append(@html)
    @positionElement(@el)


exports.HtmlLink = HtmlLink

