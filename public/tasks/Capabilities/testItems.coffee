

@stage = new Kinetic.Stage({
  container: 'container',
  width: $("#container").width(),
  height: 800
})

@Canvas = Psy.Canvas

@context = new Psy.KineticContext(stage)

@ClearEvent = new Psy.Event(new Canvas.Clear(), new Psy.Timeout({duration: 1000} ))

@Timeout1000 = new Psy.Timeout({duration: 1000} )

@SpaceKey =  new Psy.SpaceKeyResponse()

@SpaceOrTimeout5000 = new Psy.FirstResponse([ new Psy.Timeout({duration: 5000} ),SpaceKey])

@gridlayout = new Psy.GridLayout(8,8, {x:0, y:0, width:@stage.getWidth(), height:@stage.getHeight()})





@makeTrial = (stim, resp, bg=new Canvas.Background([],  "white")) ->
  =>
    console.log("starting trial!")
    stim.reset()
    resp.reset()
    new Psy.Trial([new Psy.Event(stim, resp), ClearEvent], {}, bg)


@makeResponseTrial = (resp, bg=new Canvas.Background([],  "white")) ->
  =>
    resp.reset()
    new Psy.Trial([new Psy.Event(resp, resp), ClearEvent], {}, bg)

@wrapEvents = (events, bg=new Canvas.Background([], "white")) ->
  => new Psy.Trial(events.concat(ClearEvent), {}, null, bg)



@genColoredSquareTrial = (load=4) =>

  s1a = new Psy.ExhaustiveSampler([1..6])
  s1b = new Psy.ExhaustiveSampler([1..6])
  s2 = new Psy.CombinatoricSampler(s1a,s1b)
  s3 = new Psy.ExhaustiveSampler(["red", "yellow", "orange", "blue", "pink", "brown", "black", "purple", "aqua", "fuchsia", "gray"])

  makeGroup = (gloc, cols) ->
    stims = for i in [0...gloc.length]
      new Psy.Rectangle({position: gloc[i], width: 50, height: 50, fill: cols[i] })
    new Psy.Group(stims, gridlayout)

  =>
    gloc = s2.take(4)
    cols = s3.take(4)

    group = makeGroup(gloc, cols)

    if Math.random() > .5
      # change
      index = _.shuffle([0...load])[0]

      cols[index] = s3.take(1)[0]

      probeGroup = makeGroup(gloc, cols)
    else
      console.log("no change!", index)
      probeGroup = makeGroup(gloc, cols)

    ev1 = new Psy.Event(group, Timeout1000)
    ev2 = new Psy.Event(new Psy.Clear(), new Psy.Timeout({duration: 1000} ))
    ev3 = new Psy.Event(probeGroup, Timeout1000)


    new Psy.Trial([ev1,ev2,ev3,ClearEvent], {}, new Canvas.Background([], fill= "white"))


@testSet =
  FixationCross:
    "Default Fixation": makeTrial(new Canvas.FixationCross(),SpaceOrTimeout5000)
    "Blue Fixation": makeTrial(new Canvas.FixationCross({fill: "blue"}),SpaceOrTimeout5000)
    "Fixation 200px": makeTrial(new Canvas.FixationCross({length: 200}),SpaceOrTimeout5000)
    "Fixation stroke width 20px": makeTrial(new Canvas.FixationCross({strokeWidth: 20}),SpaceOrTimeout5000)


  Text:
    "Positioning with Labels": makeTrial(new Psy.Group(
      [new Canvas.Text({content: "Center", position: "center", fontSize: 20}),
       new Canvas.Text({content: "Center Left", position: "center-left", fontSize: 20}),
       new Canvas.Text({content: "Center Right", position: "center-right", fontSize: 20}),
       new Canvas.Text({content: "Top Left", position: "top-left", fontSize: 20}),
       new Canvas.Text({content: "Top Right", position: "top-right", fontSize: 20}),
       new Canvas.Text({content: "Top Center", position: "top-center", fontSize: 20}),
       new Canvas.Text({content: "Bottom Left", position: "bottom-left", fontSize: 20}),
       new Canvas.Text({content: "Bottom Right", position: "bottom-right", fontSize: 20}),
      new Canvas.Text({content: "Bottom Center", position: "bottom-center", fontSize: 20})
      ]), SpaceKey)

    "75 Point Font": makeTrial(new Canvas.Text({content: "75 Point Font", position: "center", fontSize: 75}),SpaceKey)
    "12 Point Font": makeTrial(new Canvas.Text({content: "12 Point Font", position: "center", fontSize: 12}),SpaceKey)

    "Paragraph": makeTrial(new Canvas.Text({
      content:
        "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\n
        Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor\n
        in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident,\n
        sunt in culpa qui officia deserunt mollit anim id est laborum."
      width:800,
      fontSize: 24}),
      SpaceKey)

  Markdown:
    "Basic Example": makeTrial(new Psy.Html.Markdown("""

    A First Level Header Today tttt
    ===================
    A Second Level Header Tday tttt
    ---------------------
    ### Header 3


    Now is the time for all good men to come to
    the aid of their country. This is just a
    regular paragraph.

    The quick brown fox jumped over the lazy
    dog's back.

    > This is a blockquote.
    >
    > This is the second paragraph in the blockquote.
    >
    > ## This is an H2 in a blockquote

    ![alt text](http://www.html5canvastutorials.com/demos/assets/yoda.jpg "Title")


    """), SpaceKey)

    "An External URL": makeTrial(new Psy.Html.Markdown({url: "/tasks/Capabilities/resources/page-1.md"}), SpaceKey)


  HtmlIcon:
    Default: makeTrial(new Psy.Html.HtmlIcon(), SpaceOrTimeout5000)
    PercentagePositioning: makeTrial(new Psy.Html.HtmlIcon({label: "[50%,50%]", x: "40%", y: "40%"}), SpaceOrTimeout5000)

  HtmlLink:
    Default: makeTrial(new Psy.Html.HtmlLink(), SpaceOrTimeout5000)
    XYPositioning: makeTrial(new Psy.Html.HtmlLink({label: "[100,100]", x: 100, y: 100}), SpaceOrTimeout5000)
    PercentagePositioning: makeTrial(new Psy.Html.HtmlLink({label: "[80%,80%]", x: "80%", y: "80%"}), SpaceOrTimeout5000)

  HtmlButton:
    Default: makeTrial(new Psy.Html.HtmlButton(), SpaceOrTimeout5000)
    PercentagePositioning: makeTrial(new Psy.Html.HtmlButton({label: "[80%,80%]", x: "80%", y: "80%"}), SpaceOrTimeout5000)
    CircularButton: makeTrial(new Psy.Html.HtmlButton({label: "[50%,50%]", x: "50%", y: "50%", class: "circular"}), SpaceOrTimeout5000)
    "Button over Crosshair": makeTrial(new Psy.Group([
      new Psy.Html.HtmlButton({label: "[50%,50%]", x: "50%", y: "50%", class: "circular huge"}),
      new Canvas.FixationCross()
    ]), SpaceKey)

  HtmlRange:
    Default: makeTrial(new Psy.HtmlRange(), SpaceKey)



  Blank:
    "Black Background": makeTrial(new Canvas.Blank({fill: "black"}), SpaceOrTimeout5000)
    "Green Background": makeTrial(new Canvas.Blank({fill: "green"}), SpaceOrTimeout5000)
    "RGB (33, 55, 67)": makeTrial(new Canvas.Blank({fill: "rgb(33,55,67)"}), SpaceOrTimeout5000)

  CanvasBorder:
    "Default": makeTrial(new Canvas.CanvasBorder(), SpaceKey)
    "Blue Border": makeTrial(new Canvas.CanvasBorder({stroke: "blue"}), SpaceKey)
    "Thick Blue Border": makeTrial(new Canvas.CanvasBorder({stroke: "blue", strokeWidth: 20}), SpaceKey)

  GridLines:
    "Default GridLines": makeTrial(new Canvas.GridLines(), SpaceKey)
    "5 X 5 GridLines": makeTrial(new Canvas.GridLines({rows:5, cols:5}), SpaceKey)
    "5 X 5 Dashed GridLines": makeTrial(new Canvas.GridLines({rows:5, cols:5, dashArray: [10,5]}), SpaceKey)

  Rectangle:
    "Default Rect": makeTrial(new Canvas.Rectangle(), SpaceKey)
    "Green Square 500 by 500": makeTrial(new Canvas.Rectangle({width: 500, height: 500, fill: "green"}), SpaceOrTimeout5000)
    "Green Square Blue Stroke": makeTrial(new Canvas.Rectangle({width: 500, height: 500, fill: "green", stroke: "blue"}), SpaceOrTimeout5000)
    "Default Rect, x 50%, y 50%": makeTrial(new Canvas.Rectangle({position: ["50%","50%"]}), SpaceKey)
    "Default Rect, grid 3,3 [0,0]": makeTrial(new Canvas.Rectangle({position: [0,0], layout: new Psy.GridLayout(3,3, {x:0, y:0, width:800, height:800})}), SpaceKey)
    "Default Rect, grid 3,3 [2,2]": makeTrial(new Canvas.Rectangle({position: [2,2], layout: new Psy.GridLayout(3,3, {x:0, y:0, width:stage.getWidth(), height:stage.getHeight()})}), SpaceKey)

  Circle:
    "Default Circle": makeTrial(new Canvas.Circle(), SpaceKey)
    "Green Circle Radius 50": makeTrial(new Canvas.Circle({radius: 50, fill: "green"}), SpaceOrTimeout5000)
    "Green Circle Blue Stroke": makeTrial(new Canvas.Circle({radius: 50, fill: "green", stroke: "blue"}), SpaceOrTimeout5000)

  Arrow:
    "Default Arrow": makeTrial(new Canvas.Arrow(), SpaceKey)
    "Blue Arrow, length 200": makeTrial(new Canvas.Arrow({length: 200, fill: "blue"}), SpaceKey)
    "Blue Arrow, black stroke": makeTrial(new Canvas.Arrow({length: 200, fill: "blue", stroke: "black", strokeWidth: 4}), SpaceKey)
    "Rotating Arrow": makeTrial(new Psy.Sequence(
      for i in [0 .. 360] by 2
        new Canvas.Arrow({x:300, y:300, length: 200, fill: "black", angle: i})
      [40]), SpaceKey)

    "Rotating Arrow no clear": makeTrial(new Psy.Sequence(
      for i in [0 .. 360] by 2
        new Canvas.Arrow({x:300, y:300, length: 200, fill: "black", angle: i, opacity: i/720})
      [40], clear=false),SpaceKey)

  Picture:
    "Default Picture": makeTrial(new Canvas.Picture(), SpaceKey)
    "Default 300 X 300": makeTrial(new Canvas.Picture({width: 300, height: 300}), SpaceKey)
    "Flicker Two Images 4Hz": makeTrial(new Psy.Sequence(
      [ new Canvas.Picture(url: "images/Sunset.jpg"),
        new Canvas.Picture(url: "images/Shark.jpg")],
      [250,250], clear=true, times=50), SpaceKey)

  StartButton:
    "Start Button": makeTrial(new Canvas.StartButton({id: "start"}), new Psy.ClickResponse("start"))

  MultipleChoice:
    "Default MChoice": makeTrial(new Psy.MultipleChoice(), SpaceKey)

  Page:
    "Test Html": makeTrial(new Psy.Html.Page(), SpaceKey)
    Message: makeTrial(new Psy.Html.Page(
      html:
        """
      <div class="ui message">
        <div class="header">
          Welcome back!
        </div>
        <p>
          It's good to see you again. I have had a lot to think about since our last visit, I've changed much as a person and I can see that you have too.
        </p>
        <p>
        Perhaps we can talk about it if you have the time.
        </p>
      </div>
      <div class="ui icon message">
        <i class="inbox icon"></i>
        <div class="content">
        <div class="header">
          Have you heard about our mailing list?
        </div>
        <p>Get all the best inventions in your e-mail every day. Sign up now!</p>
        </div>
      </div>
      """
    ), SpaceKey)

  Message:
    "Default": makeTrial(new Psy.Html.Message(), SpaceKey)
    "Basic Message in Red": makeTrial(new Psy.Html.Message({
      title: "This is a massive message in red"
      content: """
        Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
        Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure
        dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non
        proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
      """
      color: "red"
      size: "massive"
    }), SpaceKey)
    "Multiple Messages": makeTrial(new Psy.Group(
      [new Psy.Html.Message({ title: "message 1", content: "This is Message 1", color: "blue"}),
       new Psy.Html.Message({ title: "message 2", content: "This is Message 2", color: "red"}),
       new Psy.Html.Message({ title: "message 3", content: "This is Message 3", color: "green"})
      ]), SpaceKey)

    "Message and Canvas Rect": makeTrial(new Psy.Group(
      [new Psy.Html.Message({ title: "message 1", content: "This is Message 1", color: "blue"}),
      new Canvas.FixationCross()]), SpaceKey)


  Instructions:
    "Simple Test": makeResponseTrial(new Psy.Html.Instructions(
      pages:
        1: Markdown: "Hello"
        2: Markdown: "Goodbye"
        3: Markdown: "Dolly"
    ))


  Group:
    "Group of Circles": makeTrial(new Psy.Group(
      [ new Canvas.Circle({x: 100, y: 150, radius:70 }),
        new Canvas.Circle({x: 250, y: 150, radius:70 }),
        new Canvas.Circle({x: 400, y: 150, radius:70 })]), SpaceKey)
    "Overlapping Circles": makeTrial(new Psy.Group(
      [ new Canvas.Circle({x: 100, y: 150, radius:100, opacity:  1, fill: "red" }),
        new Canvas.Circle({x: 250, y: 150, radius:100, opacity: .5, fill: "yellow" }),
        new Canvas.Circle({x: 175, y: 250, radius:100, opacity: .5, fill: "blue" })]), SpaceKey)
    "Colored Squares": makeTrial(new Psy.Group(
      [ new Canvas.Rectangle({x: 100, y: 50, width: 50, height: 50, fill: "red" }),
        new Canvas.Rectangle({x: 250, y: 500, width: 50, height: 50, fill: "orange" }),
        new Canvas.Rectangle({x: 200, y: 300, width: 50, height: 50, fill: "cyan" }),
        new Canvas.Rectangle({x: 65,  y: 250, width: 50, height: 50, fill: "pink" })]), SpaceKey)
    "Colored Squares on Grid": makeTrial(new Psy.Group(
      [ new Canvas.Rectangle({position: [0,0], width: 50, height: 50, fill: "red" }),
        new Canvas.Rectangle({position: [2,2], width: 60, height: 60, fill: "orange" }),
        new Canvas.Rectangle({position: [4,4], width: 70, height: 70, fill: "cyan"}),
        new Canvas.Rectangle({position: [6,6], width: 80, height: 80, fill: "pink" })], gridlayout), SpaceKey)
    "VSTM Example Trial": genColoredSquareTrial()

  Sequence:
    "Count to Three": makeTrial(new Psy.Sequence(
      [ new Canvas.Text({content: "One", position: "center"}),
        new Canvas.Text({content: "Two", position: "center"}),
        new Canvas.Text({content: "Three", position: "center"})],
      [1000, 2000, 4000]), SpaceKey)
    "Count to Three with Overlay": makeTrial(new Psy.Sequence(
      [ new Canvas.Text({content: "One", position: "center-left"}),
        new Canvas.Text({content: "Two", position: "center"}),
        new Canvas.Text({content: "Three", position: "center-right"})],
      [1000, 2000, 4000], clear=false), SpaceKey)
    "Fast Countdown": makeTrial(new Psy.Sequence(
      for i in [50..0]
        r = i*4
        g = 255 - (i*4)
        b = i
        new Canvas.Text({content: i, position: "center", fontSize: 80 + i*2, fill: "rgb(#{r},#{g},#{b})"})
      [80]), SpaceKey)
    "Repeating Squares": makeTrial(new Psy.Sequence(
      [ new Canvas.Rectangle({position: [2,2], width: 80, height: 80, fill: "red", layout: gridlayout}),
        new Canvas.Rectangle({position: [2,3], width: 80, height: 80, fill: "blue", layout: gridlayout}),
        new Canvas.Rectangle({position: [2,4], width: 80, height: 80, fill: "yellow", layout: gridlayout})
      ], [100], true, 9), SpaceKey)


  Background:
    "Background fill": wrapEvents([
      new Psy.Event(new Canvas.Text({content: "Hello,"}), Timeout1000),
      new Psy.Event(new Canvas.Text({content: "How"}), Timeout1000),
      new Psy.Event(new Canvas.Text({content: "are"}), Timeout1000),
      new Psy.Event(new Canvas.Text({content: "you"}), Timeout1000),
      new Psy.Event(new Canvas.Text({content: "Today"}), SpaceKey)],
      new Canvas.Background([new Canvas.Text({content: "I am a background stimulus", position: "bottom-center"})],  "red"))

  TextInput:
    "Default TextInput": makeTrial(new Canvas.TextInput(), SpaceKey)
    "Larger Text Input": makeTrial(new Canvas.TextInput({width: 300, height: 74}), SpaceKey)
    "Even Larger Text Input": makeTrial(new Canvas.TextInput({width: 500, height: 150}), SpaceKey)
    "Gigantic Text Input": makeTrial(new Canvas.TextInput({width: 800, height: 300}), SpaceKey)

  Dialogs:
    "Prompt": makeTrial(Timeout1000, new Psy.Prompt({ title: "How old are you?"}))
    "Confirm": makeTrial(Timeout1000, new Psy.Confirm({ message: "Do you want to continue?"}))

  DotMotion:
    "Test": makeTrial(new Psy.RandomDotMotion(), SpaceKey)

  Sound:
    Default: makeTrial(new Psy.Sound(), SpaceKey)



@activeTrial = null

window.updateTests = (name) ->
  subels = testSet[name]
  testlist = $("#test_list")
  testlist.children().not("#test_header").remove()

  for key, value of subels
    testlist.append("<li><button class='button btn-link' type='button' category=#{name}>#{key}</button></li>")


  $("#test_list > li button").click (e) ->
    key = $(this).text()
    console.log(key)
    category = $(this).attr("category")
    trial = testSet[category][key]
    if @activeTrial
      @activeTrial.stop()
    @activeTrial = trial()

    context.clearContent()
    @activeTrial.start(context)






$(document).ready =>
  #cur = $("#parent_list .active")
  categories = $("#parent_list")
  for key, value of testSet
    categories.append("<li><a href='#'>#{key}</a></li>")


  #name = cur.text()
  #name = name.replace(/\s+/g, "")
  #updateTests(name)


  $("#parent_list > li" ).click (e) ->
    cur = $("#parent_list .active")
    cur.removeClass("active")
    cur.children("li").hide()

    $(this).addClass("active")

    name = $(this).text()
    name = name.replace(/\s+/g, "")
    updateTests(name)





  #if ($(this).children("li").length == 0)
  #  $(this).append("<ul class='nav nav-list'>")
  #  for el in subels
  #    $(this).append("<li><button class='btn btn-link' type='button'>#{el}</button></li>")
  #else
  #  $(this).children("li").show()

