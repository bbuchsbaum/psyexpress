Stimulus = require("../../stimresp").Stimulus
Response = require("../../stimresp").Response
#Module = require("../../module").Module


class HtmlStimulus extends Stimulus

  tag: "div"

  div: -> $(document.createElement("div"))

  constructor: (spec) ->
    super(spec)
    @el = document.createElement(@tag)
    @el  = $(@el)


  positionElement: (el) ->
    if (@spec.x? and @spec.y?)
      el.css({
        position: "absolute"
        left: @spec.x
        top: @spec.y
      })

  centerElement: (el) ->
    el.css({
      margin: "0 auto"
      position: "absolute"
      left: "50%"
      top: "50%"
    })

  render: (context, layer) ->
    context.appendHtml(@el)

class HtmlResponse extends HtmlStimulus
  @include Response


exports.HtmlStimulus = HtmlStimulus
exports.HtmlResponse = HtmlResponse



Html = {}
Html.HtmlButton = require("./htmlbutton").HtmlButton
Html.HtmlLink = require("./htmllink").HtmlLink
Html.HtmlIcon = require("./htmlicon").HtmlIcon
Html.Instructions = require("./instructions").Instructions
Html.Markdown = require("./markdown").Markdown
Html.Message = require("./message").Message
Html.Page = require("./page").Page






exports.Html = Html