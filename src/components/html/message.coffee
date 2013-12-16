
html = require("./html")


class Message extends html.HtmlStimulus

  defaults:
    title: "Message!", content: "your content here", color: "", size: "large"

  constructor: (spec = {}) ->
    super(spec)
    @el.addClass(@messageClass())
    @title = $("<div>#{@spec.title}</div>").addClass("header")
    @content = $("<p>#{@spec.content}</p>")
    @el.append(@title)
    @el.append(@content)

  messageClass: ->
    "ui message " + @spec.color + " " + @spec.size



exports.Message = Message