Psy = require("./PsyCloud")
Bacon = require("./lib/Bacon").Bacon
_ = require('lodash')
Q = require("q")
markdown = require("./lib/markdown").markdown
{renderable, ul, li, input} = require('teacup')


if window?.performance?.now
  console.log("Using high performance timer")
  getTimestamp = -> window.performance.now()
else if window?.performance?.webkitNow
  console.log("Using webkit high performance timer")
  getTimestamp = -> window.performance.webkitNow()
else
  console.log("Using low performance timer");
  getTimestamp = -> new Date().getTime()


doTimer = (length, oncomplete) ->
  start = getTimestamp()
  instance = ->

    diff = (getTimestamp() - start)
    if diff >= length
      oncomplete(diff)
    else
      half = Math.max((length - diff)/2,1)
      if half < 20
        half = 1
      setTimeout instance, half

  setTimeout instance, 1


@browserBackDisabled = false

disableBrowserBack = ->
  if not @browserBackDisabled
    rx = /INPUT|SELECT|TEXTAREA/i

    @browserBackDisabled = true

    $(document).bind("keydown keypress", (e) ->
      if e.which is 8
        if !rx.test(e.target.tagName) or e.target.disabled or e.target.readOnly
          e.preventDefault())


#doTimer = (length, resolution, oninstance, oncomplete) ->
#  instance = ->
#    if count++ is steps
#      oncomplete steps, count
#    else
#      oninstance steps, count
#      diff = (getTimestamp() - start) - (count * speed)
#      window.setTimeout instance, (speed - diff)
#  steps = (length / 100) * (resolution / 10)
#  speed = length / steps
#  count = 0
#  start = getTimestamp()
#  window.setTimeout instance, speed

isPercentage = (perc) -> _.isString(perc) and perc.slice(-1) is "%"

convertPercentageToFraction = (perc, dim) ->
  frac = parseFloat(perc)/100
  frac = Math.min(1,frac)
  frac = Math.max(0,frac)
  frac * dim

convertToCoordinate = (val, d) ->
  if isPercentage val
    val = convertPercentageToFraction(val, d)
  else
    Math.min(val, d)

computeGridCells = (rows, cols, bounds) ->
  for row in [0...rows]
    for col in [0...cols]
      {
        x: bounds.x + bounds.width/cols * col
        y: bounds.y + bounds.height/rows * row
        width:  bounds.width/cols
        height: bounds.height/rows
      }


exports.Layout =
class Layout

  constructor: ->

  computePosition: (dim, stim, constraints) ->


exports.AbsoluteLayout =
class AbsoluteLayout extends exports.Layout

  computePosition: (dim, constraints) ->
    x = convertToCoordinate(constraints[0], dim[0])
    y = convertToCoordinate(constraints[1], dim[1])
    [x,y]


#exports.DefaultLayout =
#class DefaultLayout extends exports.Layout





exports.GridLayout =
class GridLayout extends exports.Layout
  constructor: (@rows, @cols, @bounds) ->
    @ncells = @rows*@cols
    @cells = @computeCells()

  computeCells: -> computeGridCells(@rows, @cols, @bounds)

  #cellPosition: (dim, constraints) ->

  computePosition: (dim, constraints) ->
    if dim[0] != @bounds.width and dim[1] != @bounds.height
      @bounds.width = dim[0]
      @bounds.height = dim[1]
      @cells = @computeCells()

    cell = @cells[constraints[0]][constraints[1]]

    [cell.x + cell.width/2, cell.y + cell.height/2]



class Stimulus

  constructor: (spec, defaultArgs) ->
    @spec = _.defaults(spec, defaultArgs)

    if @spec?.id?
      @id = @spec.id
    else
      @id = _.uniqueId("stim_")

  overlay: false

  layout: new AbsoluteLayout()

  stopped: false

  computeCoordinates: (context, position) ->
    if position
      cpos = @layout.computePosition([context.width(), context.height()], position)
      cpos
    else if @spec.x and @spec.y
      [@spec.x, @spec.y]
    else [0,0]

  reset: -> @stopped = false

  render: (context, layer) ->

  stop: (context) -> @stopped = true

  #id: -> @spec.id or _.uniqueId()

exports.Stimulus = Stimulus

class Response extends Stimulus
  constructor: (spec, defaultArgs) ->
    super(spec, defaultArgs)

  activate: (context) ->

exports.Response = Response

tmp1 = new Psy.EventData("hello", "24", {x: 8})
tmp2 = new Psy.EventData("goodbye", "24", {x: 8})
tmp3 = new Psy.EventData("goyyyyyy", "29", {x: 8})

elog = new Psy.EventDataLog()
elog.push(tmp1)
elog.push(tmp2)

console.log("elog last", elog.last())
console.log("elog find last", elog.findLast("24"))

exports.Timeout =
class Timeout extends Response

  constructor: (spec = {}) ->
    super(spec, { duration: 2000 } )

    @oninstance = (steps, count) -> console.log(steps, count)

  activate: (context) ->
    deferred = Q.defer()

    doTimer(@spec.duration, (diff) => deferred.resolve({timeout: diff, requested: @spec.duration}))
    deferred.promise



exports.Prompt =
class Prompt extends Response
  constructor: (spec = {}) ->
    super(spec, { title: "", delay: 0, defaultValue: "" })

  activate: (context) ->
    deferred = Q.defer()
    promise = Q.delay(@spec.delay)
    promise.then((f) =>
      vex.dialog.prompt
        message: @spec.title
        placeholder: @spec.defaultValue
        className: 'vex-theme-wireframe'
        callback: (value) -> deferred.resolve(value)
    )

      #result = window.prompt(@spec.title, @spec.defaultValue)
      #deferred.resolve(result))
    deferred.promise

exports.Confirm =
  class Confirm extends Response
    constructor: (spec = {}) ->
      super(spec, { message: "", delay: 0, defaultValue: "" })

    activate: (context) ->
      deferred = Q.defer()
      promise = Q.delay(@spec.delay)
      promise.then((f) =>
        vex.dialog.confirm
          message: @spec.message
          className: 'vex-theme-wireframe'
          callback: (value) -> deferred.resolve(value)
      )

      #result = window.prompt(@spec.title, @spec.defaultValue)
      #deferred.resolve(result))
      deferred.promise


exports.TypedResponse =
class TypedResponse
  constructor: (spec = {}) ->
    super(spec,  { left: 250, top: 250, defaultValue: "" })

  activate: (context) ->
    deferred = Q.defer()

    enterPressed = false
    freeText = "____"
    text = new fabric.Text(freeText, { top: @spec.top, left: @spec.left, fontSize: 50, textAlign: "left" })
    context.canvas.add(text)
    xoffset = text.width/2

    cursor = new fabric.Line([@spec.left, @spec.top + text.height/2, @spec.left, @spec.top-(text.height/2)])
    context.canvas.add(cursor)

    keyStream = context.keypressStream()
    keyStream.takeWhile((x) => enterPressed is false).onValue((event) =>

      if event.keyCode == 13
        enterPressed = true
        deferred.resolve(freeText)
      else
        char = String.fromCharCode(event.keyCode)
        freeText = freeText + char
        text.setText(freeText)
        text.set("left": @spec.left + (text.width/2 - xoffset))
        console.log(text.width)
        console.log(text.height)
        #console.log(text.getCenterPoint())
        #console.log(text.getBoundingRect())
        context.canvas.renderAll())


    deferred.promise



exports.MousePressResponse =
class MousePressResponse extends Response

  constructor: ->
    super({}, {})

  activate: (context) ->
    deferred = Q.de fer()
    mouse = context.mousepressStream()
    mouse.stream.take(1).onValue((event) =>
                               mouse.stop()
                               deferred.resolve(event))
    deferred.promise


exports.KeyPressResponse =
class KeyPressResponse extends Response
  constructor: (spec = {}) ->
    super(spec, { keys: ['n', 'm'], correct: ['n'], timeout: 3000} )

  activate: (context) ->
    @startTime = getTimestamp()
    deferred = Q.defer()
    keyStream = context.keypressStream()
    keyStream.filter((event) =>
      char = String.fromCharCode(event.keyCode)
      _.contains(@spec.keys, char)).take(1).onValue((filtered) =>
                                Acc = _.contains(@spec.correct, String.fromCharCode(filtered.keyCode))
                                timestamp = getTimestamp()
                                resp = new Psy.EventData("KeyPress", @id,
                                  KeyTime: timestamp
                                  RT: timestamp - @startTime
                                  Accuracy: Acc
                                  KeyChar: String.fromCharCode(filtered.keyCode))

                                context.pushEventData(resp)

                                context.logEvent("KeyPress", getTimestamp())
                                context.logEvent("$ACC", Acc)

                                deferred.resolve(resp))

    deferred.promise

exports.SpaceKeyResponse =
class SpaceKeyResponse extends Response
  constructor: (spec = {}) ->
    super(spec, {})

  activate: (context) ->

    deferred = Q.defer()
    keyStream = context.keypressStream()
    keyStream.filter((event) =>
      char = String.fromCharCode(event.keyCode)
      event.keyCode == 32).take(1).onValue((event) =>
        context.logEvent("SpaceKey", getTimestamp())
        deferred.resolve(event))

    deferred.promise

exports.FirstResponse =
class FirstResponse extends Response
  constructor: (@responses) ->
    super({}, {})

  activate: (context) ->
    deferred = Q.defer()
    promises = _.map(@responses, (resp) => resp.activate(context).then(=> deferred.resolve(resp)))
    deferred.promise

exports.ClickResponse =
class ClickResponse extends Response
  constructor: (@refid) ->

  activate: (context) ->
    element = context.stage.get("#" + @refid)

    if not element
      throw "cannot find element with id" + @refid

    deferred = Q.defer()
    element.on "click", (ev) =>
      context.logEvent("Click", getTimestamp())
      deferred.resolve(ev)

    deferred.promise


exports.GridLines =
class GridLines extends Stimulus
  constructor: (spec = {}) ->
    super(spec, { x: 0, y: 0, rows: 3, cols: 3, stroke: "black", strokeWidth: 2})

  render: (context, layer) ->
    for i in [0..@spec.rows]
      y = @spec.y + (i * context.height()/@spec.rows)
      line = new Kinetic.Line({
        points: [@spec.x, y, @spec.x + context.width(), y]
        stroke: @spec.stroke
        strokeWidth: @spec.strokeWidth
        dashArray: @spec.dashArray
      })

      layer.add(line)

    for i in [0..@spec.cols]
      x = @spec.x + (i * context.width()/@spec.cols)
      line = new Kinetic.Line({
        points: [x, @spec.y, x, @spec.y + context.height()]
        stroke: @spec.stroke
        strokeWidth: @spec.strokeWidth
        dashArray: @spec.dashArray
      })

      layer.add(line)




exports.TextInput =
class TextInput extends Stimulus
  constructor: (spec = {}) ->
    disableBrowserBack()
    super(spec, { x: 100, y: 100, width: 200, height: 40, defaultValue: "", fill: "#FAF5E6", stroke: "#0099FF", strokeWidth: 1, content: "" })

  getChar: (e) ->
    # key is not shift
    if e.keyCode!=16
      # key is a letter
      if e.keyCode >= 65 && e.keyCode <= 90
        if e.shiftKey
          String.fromCharCode(e.keyCode)
        else
          String.fromCharCode(e.keyCode + 32)
      else if e.keyCode >= 48 && e.keyCode <=57
        String.fromCharCode(e.keyCode)
      else
        #console.log("key code is",e.keyCode)
        switch e.keyCode
          when 186 then ";"
          when 187 then "="
          when 188 then ","
          when 189 then "-"
          else ""
    else
      String.fromCharCode(e.keyCode)

  animateCursor: (layer, cursor) ->
    flashTime = 0
    new Kinetic.Animation((frame) =>
      if frame.time > (flashTime + 500)
        flashTime = frame.time
        if cursor.getOpacity() == 1
          cursor.setOpacity(0)
        else
          cursor.setOpacity(1)
        layer.draw()
    , layer)




  render: (context, layer) ->

    textRect = new Kinetic.Rect({x: @spec.x, y: @spec.y, width: @spec.width, height: @spec.height, fill: @spec.fill, cornerRadius: 4, lineJoin: "round", stroke: @spec.stroke, strokeWidth: @spec.strokeWidth})
    textContent = @spec.content


    fsize =  .85 * @spec.height

    text = new Kinetic.Text({text: @spec.content, x: @spec.x+2, y: @spec.y - 5, height: @spec.height, fontSize: fsize, fill: "black", padding: 10, align: "left"})
    cursor = new Kinetic.Rect({x: text.getX() + text.getWidth() - 7, y: @spec.y + 5, width: 1.5, height: text.getHeight() - 10, fill: "black"})

    enterPressed = false
    keyStream = context.keydownStream()
    keyStream.takeWhile((x) => enterPressed is false and not @stopped).onValue((event) =>

      if event.keyCode == 13
        ## Enter Key, Submit Text
        enterPressed = true
        #deferred.resolve(freeText)
      else if event.keyCode == 8
        ## Backspace
        #console.log("delete key")
        textContent = textContent.slice(0, - 1)
        text.setText(textContent)
        cursor.setX(text.getX() + text.getWidth() - 7)
        layer.draw()
      else if text.getWidth() > textRect.getWidth()
        return
      else
        char = @getChar(event)
        #console.log("char is", char)
        textContent += char

        text.setText(textContent)
        cursor.setX(text.getX() + text.getWidth() - 7)
        layer.draw())

    cursorBlink = @animateCursor(layer, cursor)
    cursorBlink.start()

    group = new Kinetic.Group({})


    group.add(textRect)
    group.add(cursor)
    group.add(text)
    layer.add(group)


exports.Sound =
class Sound

  constructor: (@url) ->
    @sound = new buzz.sound(@url)

  render: (context) ->
    @sound.play()


exports.Picture =
class Picture extends Stimulus
  constructor: (spec = {} ) ->
    super(spec, { url: "http://www.html5canvastutorials.com/demos/assets/yoda.jpg", x:0, y: 0 })
    @imageObj = new Image()
    @image = null

    @imageObj.onload = =>

      @image = new Kinetic.Image({
        x: @spec.x,
        y: @spec.y,
        image: @imageObj,
        width: @spec.width or @imageObj.width,
        height: @spec.height or @imageObj.height
      })

    @imageObj.src = @spec.url



  render: (context, layer) ->
    layer.add(@image)
    #context.contentLayer.draw()




exports.Group =
class Group extends Stimulus

  constructor: (@stims, layout) ->
    super({}, {})
    #@overlay = true
    if layout
      @layout = layout
      for stim in @stims
        stim.layout = layout
        #stim.overlay=true


  render: (context, layer) ->
    for stim in @stims
      stim.render(context, layer)

# VerticalGroup lays out stimuli from top to bottom


exports.Background =
class Background extends Stimulus

  constructor:  (@stims=[], @fill= "white") ->
    super({}, {})

  render: (context, layer) ->
    background = new Kinetic.Rect({
      x: 0,
      y: 0,
      width: context.width(),
      height: context.height(),
      name: 'background'
      fill: @fill
    })


    layer.add(background)

    for stim in @stims
      stim.render(context, layer)


exports.Sequence =
class Sequence extends Stimulus

  constructor: (@stims, @soa, @clear=true, @times=1) ->
    super({}, {})
    if (@soa.length != @stims.length)
      @soa = Psy.repLen(@soa, @stims.length)

    @onsets = for i in [0...@soa.length]
      _.reduce(@soa[0..i], (x, acc) -> x + acc)




  genseq: (context, layer) ->
    deferred = Q.defer()
    _.forEach([0...@stims.length], (i) =>
      console.log("genseq", i)
      ev = new Timeout({duration: @onsets[i]})
      stim = @stims[i]

      ev.activate(context).then(=>
        if not @stopped
          if @clear
            context.clearContent()

          stim.render(context, layer)
          context.draw()
        if i == @stims.length-1
          deferred.resolve(1)
      )
    )

    deferred.promise


  render: (context, layer) ->
    result = Q.resolve(0)
    for i in [0...@times]
      result = result.then(=> @genseq(context,layer))
    result

  #stop: (context) -> @stopped = true


exports.Blank =
class Blank extends Stimulus

  constructor: (spec={}) ->
    super(spec, { fill: "white" })


  render: (context, layer) ->
    blank = new Kinetic.Rect({ x: 0, y: 0, width: context.width(), height: context.height(), fill: @spec.fill })
    layer.add(blank)


exports.Clear =
class Clear extends Stimulus
  constructor: (spec = {}) ->
    super(spec, {})

  render: (context, layer) ->
    context.clearContent(true)

exports.Arrow =
class Arrow extends Stimulus
  constructor: (spec={}) ->
    super(spec, { x: 100, y: 100, length: 100, angle: 0, thickness: 40, fill: "red", arrowSize: 50})

  render: (context, layer) ->
    rect = new Kinetic.Rect({x: 0, y: 0, width: @spec.length, height: @spec.thickness, fill: @spec.fill, stroke: @spec.stroke, strokeWidth: @spec.strokeWidth, opacity: @spec.opacity})

    _this = @

    triangle = new Kinetic.Shape({
      drawFunc: (cx) ->

        cx.beginPath()

        cx.moveTo(_this.spec.length, - _this.spec.arrowSize/2.0)

        cx.lineTo(_this.spec.length + _this.spec.arrowSize, _this.spec.thickness/2.0)

        cx.lineTo(_this.spec.length, _this.spec.thickness + _this.spec.arrowSize/2.0)

        cx.closePath()
        cx.fillStrokeShape(this)

      fill: _this.spec.fill
      stroke: @spec.stroke
      strokeWidth: @spec.strokeWidth
      opacity: @spec.opacity

    })


    group = new Kinetic.Group({x: @spec.x, y: @spec.y, rotationDeg: @spec.angle, offset: [0, @spec.thickness/2.0]})
    group.add(rect)
    group.add(triangle)

    layer.add(group)



exports.Rectangle =
class Rectangle extends Stimulus
  constructor: (spec = {}) ->
    super(spec, { x: 0, y: 0, width: 100, height: 100, fill: 'red'} )
    @spec = _.omit(@spec, (value, key) -> not value)

    if @spec.layout?
      @layout = @spec.layout

  render: (context, layer) ->

    coords = @computeCoordinates(context, @spec.position)
    rect = new Kinetic.Rect({ x: coords[0], y: coords[1], width: @spec.width, height: @spec.height, fill: @spec.fill, stroke: @spec.stroke, strokeWidth: @spec.strokeWidth })
    layer.add(rect)


exports.Circle =
class Circle extends Stimulus
    constructor: (spec = {}) ->
      super(spec, { x: 100, y: 100, radius: 50, fill: 'red', opacity: 1})

    render: (context, layer) ->
      circ = new Kinetic.Circle({ x: @spec.x, y: @spec.y, radius: @spec.radius, fill: @spec.fill, stroke: @spec.stroke, strokeWidth: @spec.strokeWidth, opacity: @spec.opacity })
      layer.add(circ)
      #context.contentLayer.draw()



exports.FixationCross =
class FixationCross extends Stimulus
  constructor: (spec = {}) ->
    super(spec, { strokeWidth: 8, length: 150, fill: 'black'})

  render: (context, layer) ->

    x = context.width()/2
    y = context.height()/2

    horz = new Kinetic.Rect({ x: x - @spec.length/2, y: y, width: @spec.length, height: @spec.strokeWidth, fill: @spec.fill })
    vert = new Kinetic.Rect({ x: x - @spec.strokeWidth/2, y: y - @spec.length/2 + @spec.strokeWidth/2, width: @spec.strokeWidth, height: @spec.length, fill: @spec.fill })
    group = new Kinetic.Group()
    group.add(horz)
    group.add(vert)

    layer.add(group)


exports.CanvasBorder =
class CanvasBorder extends Stimulus
  constructor: (spec = {}) ->
    super(spec, { strokeWidth: 5, stroke: "black" })

  render: (context, layer) ->
    border = new Kinetic.Rect({ x: 0, y: 0, width: context.width(), height: context.height(), strokeWidth: @spec.strokeWidth, stroke: @spec.stroke })
    layer.add(border)


exports.StartButton =
class StartButton extends Stimulus
  constructor: (spec = {}) ->
    super(spec, { width: 150, height: 75 })

  render: (context, layer) ->

    xcenter = context.width()/2
    ycenter = context.height()/2

    group = new Kinetic.Group({id: @spec.id})

    text = new Kinetic.Text({text: "Start", x: xcenter - @spec.width/2, y: ycenter - @spec.height/2, width: @spec.width, height: @spec.height, fontSize: 30, fill: "white", fontFamily: "Arial", align: "center", padding: 20})
    button = new Kinetic.Rect({x: xcenter - @spec.width/2, y: ycenter - text.getHeight()/2, width: @spec.width, height: text.getHeight(), fill: "black", cornerRadius: 10,  stroke: "LightSteelBlue", strokeWidth: 5})
    group.add(button)
    group.add(text)

    layer.add(group)


position = (pos, offx, offy, width, height, xy) ->
  switch pos
    when "center" then [offx + width * .5, offy + height * .5]
    when "center-left" then [offx + width * 1/6, offy + height * .5]
    when "center-right" then [offx + width * 5/6, offy + height * .5]
    when "top-left" then [offx + width * 1/6, offy + height * 1/6]
    when "top-right" then [offx + width * 5/6, offy + height * 1/6]
    when "top-center" then [offx + width * .5, offy + height * 1/6]
    when "bottom-left" then [offx + width * 1/6, offy + height * 5/6]
    when "bottom-right" then [offx + width * 5/6, offy + height * 5/6]
    when "bottom-center" then [offx + width * .5, offy + height * 5/6]

    else xy

exports.Text =
class Text extends Stimulus
  constructor: (spec = {}) ->
    super(spec, { content: "Text", x: 5, y: 5, width: null, fill: "black", fontSize: 50, fontFamily: "Arial", lineHeight: 1, textAlign: "center", position: null} )

  render: (context, layer) ->
    #console.log("trial meta ", context.currentTrial.meta)

    text = new Kinetic.Text({
      x: @spec.x,
      y: @spec.y,
      text: @spec.content,
      fontSize: @spec.fontSize,
      fontFamily: @spec.fontFamily,
      fill: @spec.fill
      #width: @spec.width or context.width()
      listening: false
    })

    if @spec.position
      xy = position(@spec.position, -text.getWidth()/2, -text.getHeight()/2, context.width(), context.height(), [@spec.x, @spec.y])
      text.setPosition({x:xy[0], y:xy[1]})



    layer.add(text)


exports.Paragraph =
class Paragraph extends Stimulus
  constructor: (spec = {}) ->
    super(spec, { content: "", x: 50, y: 50, width: 600, fill: "black", fontSize: 18, fontFamily: "Arial", lineHeight: 1, textAlign: "center", position: null} )

exports.Markdown =
class Markdown extends exports.Stimulus
  constructor: (spec={}) ->
    super(spec, {})
    if _.isString(spec)
      @spec = {}
      @spec.content = spec

    @html = $("<div></div>")

    if @spec.url?
      $.ajax(
        url: @spec.url
        success: (result) =>
          @spec.content = result
          @html.append( markdown.toHTML(@spec.content))
        error: (result) =>
          console.log("ajax failure", result)
      )
    else
      @html.append($(markdown.toHTML(@spec.content)))

    @html.addClass("markdown")

  render: (context, layer) ->
    console.log(@html)
    context.clearHtml()
    context.appendHtml(@html)


exports.Message =
class Message extends Stimulus


  constructor: (spec={}) ->
    super(spec, {title: "Message!", content: "your content here", color: "", size: "large"})
    @message = $("<div></div>").addClass(@messageClass())
    @title =  $("<div>#{@spec.title}</div>").addClass("header")
    @content = $("<p>#{@spec.content}</p>")
    @message.append(@title)
    @message.append(@content)

  messageClass: ->
    "ui message " + @spec.color + " " + @spec.size

  render: (context, layer) ->
    console.log(@message.html())
    context.appendHtml(@message)




exports.Page =
class Page extends Stimulus
  constructor: (spec={}) ->
    super(spec, {html: "<div>HTML Page</div>"})
    @html = @spec.html

  render: (context, layer) ->
    context.appendHtml(@html)


exports.Instructions =
class Instructions extends Response
  constructor: (spec={}) ->
    super(spec, {})

    @pages = for key, value of @spec.pages
      type = _.keys(value)[0]
      ## assumes type is Markdown
      content = _.values(value)[0]
      console.log("type", type)
      console.log("value", value)
      md = new Markdown(content)
      div=$("<div></div>")
      $(div).addClass("ui stacked segment").append(md.html)

    @menu = $("<div></div>").addClass("ui borderless pagination menu")


    #@back = $("""<div class="ui green disabled labeled icon button"><i class="left arrow icon"></i>Back</div>""").attr("id", "instructions_back")
    #@next = $("""<div class="ui green right labeled icon button"><i class="right arrow icon"></i>Next</div>""").attr("id", "instructions_next")

    @back = $("""
              <a class="item">
                <i class="icon left arrow"></i>  Previous
               </a>""").attr("id", "instructions_back")

    @next = $("""
              <a class="item">
              Next <i class="icon right arrow"></i>
              </a>""").attr("id", "instructions_next")

    @menu.append(@back).append("\n")
    @items = for i in [1..@pages.length]
      itm = $("""<a class="item">#{i}</a>""")
      @menu.append(itm).append("\n")
      itm
    @items[0].addClass("active")
    @menu.append(@next).css("position", "absolute").css("right", "15px")

    #@nav = $("<div></div>").addClass("ui borderless pagination menu").append(@back).append("\n").append(@next).css("position", "absolute").css("right", "0px")

    @currentPage = 0

  activate: (context) ->

    @deferred = Q.defer()
    @deferred.promise

  render: (context, layer) ->
    @next.click (e) =>
      if (@currentPage < (@pages.length-1))
        @items[@currentPage].removeClass("active")
        @currentPage += 1
        @items[@currentPage].addClass("active")
        context.clearHtml()
        @render(context)
      else
        @deferred.resolve(0)

    @back.click (e) =>
      console.log("back click!")
      if (@currentPage > 0)
        @items[@currentPage].removeClass("active")
        @currentPage -= 1
        @items[@currentPage].addClass("active")
        context.clearHtml()
        @render(context)

    @back.removeClass("disabled") if @currentPage > 0

    $(@pages[@currentPage]).css(
      "min-height": context.height() - 50
    )

    context.appendHtml(@pages[@currentPage])
    context.appendHtml(@menu)
    #context.appendHtml(@nav)




exports.HtmlIcon =
class HtmlIcon extends Stimulus
  constructor: (spec={}) ->
    super(spec, {glyph: "plane", size: "massive"})
    @html = $("<i></i>")
    @html.addClass(@spec.glyph + " " + @spec.size + " icon")

    if (@spec.x? and @spec.y?)
      @html.css({
        position: "absolute"
        left: @spec.x
        top: @spec.y
      })

  render: (context, layer) ->

    context.appendHtml(@html)
    console.log("width of icon is", $(@html).width())
    console.log("height of icon is", $(@html).height())


exports.HtmlLink =
class HtmlLink extends exports.Stimulus
  constructor: (spec={}) ->
    super(spec, {label: "link"})
    @html = $("""<a href='#'>#{@spec.label}</a>""")

    if (@spec.x? and @spec.y)
      @html.css({
        position: "absolute"
        left: @spec.x
        top: @spec.y
      })

  render: (context, layer) ->
    context.appendHtml(@html)


exports.HtmlButton =
  class HtmlButton extends Stimulus
    constructor: (spec={}) ->
      super(spec, {label: "Next", class: ""})

      @html = $("""<div class='ui button'>
               #{@spec.label}</div>""")

      if (@spec.x? and @spec.y)
        @html.css({
          position: "absolute"
          left: @spec.x
          top: @spec.y
        }).addClass(@spec.class)

    render: (context, layer) ->
      context.appendHtml(@html)



exports.MultipleChoice =
class MultipleChoice extends Stimulus
  constructor: (spec={}) ->
    super(spec, { question: "What is your name?", options: ["Bill", "John", "Fred"], x: 10, y: 10, fill: "black", fontSize: 24, fontFamily: "Arial", textAlign: "center", position: null})

  render: (context, layer) ->
    questionText = new Kinetic.Text({
      x: @spec.x
      y: @spec.y
      text: @spec.question
      fontSize: @spec.fontSize
      fontFamily: @spec.fontFamily
      fill: @spec.fill
    })

    layer.add(questionText)

    for i in [0...@spec.options.length]
      choice = new Kinetic.Text({
        x: @spec.x + 5
        y: questionText.getHeight() * (i+1) + 30
        text: (i+1) + ") " + @spec.options[i]
        fontSize: @spec.fontSize
        fontFamily: @spec.fontFamily
        fill: @spec.fill
        padding: 20
        align: 'left'
      })

      layer.add(choice)




exports.KineticContext =
class KineticContext extends Psy.ExperimentContext

  constructor: (@stage) ->
    super(new KineticStimFactory())
    @contentLayer = new Kinetic.Layer({clearBeforeDraw: true})
    @backgroundLayer = new Kinetic.Layer({clearBeforeDraw: true})
    @background = new Background([], fill: "white")

    @stage.add(@backgroundLayer)
    @stage.add(@contentLayer)


    @backgroundLayer.on("click", -> console.log("background layer click"))

    @stage.on("mousedown", -> console.log("stage mouse down"))
    @stage.getContent().addEventListener('mousedown', () -> console.log("stage dom click"))

    @insertHTMLDiv()

    $("document").keydown ->
      console.log("container key down!!!!")




  insertHTMLDiv: ->
    $("canvas").css("position", "absolute")
    $(".kineticjs-content").css("position", "absolute")


    $("#container" ).append("""
      <div id="htmlcontainer" class="htmllayer"></div>
      """)

    $("#htmlcontainer").css(
      position: "absolute"
      "z-index": 999
      outline: "none"
      padding: "5px"
    )

    $("#container").attr("tabindex", 0)
    $("#container").css("outline", "none")
    $("#container").css("padding", "5px")


  clearHtml: ->
    $("#htmlcontainer").empty()
    $("#htmlcontainer").hide()

  appendHtml: (input) ->
    $("#htmlcontainer").addClass("htmllayer")
    $("#htmlcontainer").append(input)
    $("#htmlcontainer").show()

  hideHtml: ->
    $("#htmlcontainer").hide()
    #$("#htmlcontainer").empty()



  setBackground: (newBackground) ->
    @background = newBackground
    @backgroundLayer.removeChildren()
    @background.render(this, @backgroundLayer)

  drawBackground: -> @backgroundLayer.draw()

  clearBackground: ->
    @backgroundLayer.removeChildren()

  clearContent: (draw=false) ->
    #@hideHtml()
    @clearHtml()
    @contentLayer.removeChildren()
    if draw
      @draw()


  draw: ->
    $('#container' ).focus()
    #@background.render(this, @backgroundLayer)
    @backgroundLayer.draw()
    @contentLayer.draw()
    #@stage.draw()


  width: -> @stage.getWidth()

  height: -> @stage.getHeight()

  offsetX: -> @stage.getOffsetX()

  offsetY: -> @stage.getOffsetY()



  keydownStream: -> $("body").asEventStream("keydown")


  keypressStream: -> $("body").asEventStream("keypress")

  mousepressStream: ->
    class MouseBus
      constructor: () ->
        @stream = new Bacon.Bus()

        @handler = (x) =>
          @stream.push(x)

        @stage.on("mousedown", @handler)
        #@eventLayer.on('mousedown', @handler)
        #@stage.getContent().addEventListener('mousedown', @handler)

      stop: ->
        #@stage.getContent().removeEventListener("mousedown", @handler)
        #@eventLayer.off('mousedown', @handler)
        @stage.off("mousedown", @handler)
        @stream.end()


    #new MouseBus(@eventLayer)
    new MouseBus()


exports.KineticStimFactory =
class KineticStimFactory extends Psy.StimFactory


  makeLayout: (name, params, context) ->
    switch name
      when "Grid"
        new GridLayout(params[0], params[1], {x: 0, y: 0, width: context.width(), height: context.height()})

  makeInstructions: (spec) ->
    new Instructions(spec)


  makeStimulus: (name, params, context) ->

    callee = arguments.callee

    switch name
      when "FixationCross" then new FixationCross(params)
      when "Clear" then new Clear(params)
      when "Group"
        names = _.map(params.stims, (stim) -> _.keys(stim)[0])
        props = _.map(params.stims, (stim) -> _.values(stim)[0])
        stims = for i in [0...names.length]
          callee(names[i], props[i])

        layoutName = _.keys(params.layout)[0]
        layoutParams = _.values(params.layout)[0]

        new Group(stims, @makeLayout(layoutName, layoutParams, context))

      when "Instructions" then new Instructions(params)
      when "Rectangle" then new Rectangle(params)
      when "Text" then new Text(params)
      when "HtmlIcon" then new HtmlIcon(params)

      else throw "No Stimulus type of name #{name}"

  makeResponse: (name, params, context) ->
    switch name
      when "KeyPress" then new KeyPressResponse(params)
      when "Timeout" then new Timeout(params)
      else throw "No Response type of name #{name}"

  makeEvent: (stim, response) -> new Psy.Event(stim, response)



#x = new Timeout({duration: 22})
#prom = x.activate()
#prom.then( (resp) ->
#  console.log("resp", resp)
#)

#console.log(new Response().id)