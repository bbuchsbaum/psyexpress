html = require("./html")
marked = require("marked")


class Markdown extends html.HtmlStimulus

  constructor: (spec = {}) ->
    super(spec)
    if _.isString(spec)
      @spec = {}
      @spec.content = spec


    if @spec.url?
      $.ajax(
        url: @spec.url
        success: (result) =>
          @spec.content = result
          @el.append(marked(@spec.content))
        error: (result) =>
          console.log("ajax failure", result)
      )
    else
      @el.append($(marked(@spec.content)))

    @el.addClass("markdown")



exports.Markdown = Markdown