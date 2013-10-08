

@stage = new Kinetic.Stage({
  container: 'container',
  width: $("#container").width(),
  height: 800
})

@context = new Psy.KineticContext(stage)

@ClearEvent = new Psy.Event(new Psy.Clear(), new Psy.Timeout({duration: 100} ))

@Timeout1000 = new Psy.Timeout({duration: 1000} )

@SpaceKey =  new Psy.SpaceKeyResponse()

@SpaceOrTimeout5000 = new Psy.FirstResponse([ new Psy.Timeout({duration: 5000} ),SpaceKey])

@gridlayout = new Psy.GridLayout(8,8, {x:0, y:0, width:@stage.getWidth(), height:@stage.getHeight()})



@makeTrial = (stim, resp, bg=new Psy.Background([], fill= "gray")) ->
  =>
    stim.reset()
    resp.reset()
    new Psy.Trial([new Psy.Event(stim, resp), ClearEvent], {}, bg)

@wrapEvents = (events, bg=new Psy.Background([], fill= "white")) ->
  => new Psy.Trial(events.concat(ClearEvent), {}, bg)



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
      console.log("index", index)
      console.log("old cols", cols)
      cols[index] = s3.take(1)[0]
      console.log("new cols", cols)
      probeGroup = makeGroup(gloc, cols)
    else
      console.log("no change!", index)
      probeGroup = makeGroup(gloc, cols)

    ev1 = new Psy.Event(group, Timeout1000)
    ev2 = new Psy.Event(new Psy.Clear(), new Psy.Timeout({duration: 1000} ))
    ev3 = new Psy.Event(probeGroup, Timeout1000)


    new Psy.Trial([ev1,ev2,ev3,ClearEvent], {}, new Psy.Background([], fill= "white"))


@testSet =
  FixationCross:
    "Default Fixation": makeTrial(new Psy.FixationCross(),SpaceOrTimeout5000)
    "Blue Fixation": makeTrial(new Psy.FixationCross({fill: "blue"}),SpaceOrTimeout5000)
    "Fixation 200px": makeTrial(new Psy.FixationCross({length: 200}),SpaceOrTimeout5000)
    "Fixation stroke width 20px": makeTrial(new Psy.FixationCross({strokeWidth: 20}),SpaceOrTimeout5000)


  Text:
    "Positioning with Labels": makeTrial(new Psy.Group(
      [new Psy.Text({content: "Center", position: "center", fontSize: 20}),
       new Psy.Text({content: "Center Left", position: "center-left", fontSize: 20}),
       new Psy.Text({content: "Center Right", position: "center-right", fontSize: 20}),
       new Psy.Text({content: "Top Left", position: "top-left", fontSize: 20}),
       new Psy.Text({content: "Top Right", position: "top-right", fontSize: 20}),
       new Psy.Text({content: "Top Center", position: "top-center", fontSize: 20}),
       new Psy.Text({content: "Bottom Left", position: "bottom-left", fontSize: 20}),
       new Psy.Text({content: "Bottom Right", position: "bottom-right", fontSize: 20}),
       new Psy.Text({content: "Bottom Center", position: "bottom-center", fontSize: 20})]), SpaceKey)

    "75 Point Font": makeTrial(new Psy.Text({content: "75 Point Font", position: "center", fontSize: 75}),SpaceOrTimeout5000)
    "12 Point Font": makeTrial(new Psy.Text({content: "12 Point Font", position: "center", fontSize: 12}),SpaceOrTimeout5000)



  Blank:
    "Black Background": makeTrial(new Psy.Blank({fill: "black"}), SpaceOrTimeout5000)
    "Green Background": makeTrial(new Psy.Blank({fill: "green"}), SpaceOrTimeout5000)
    "RGB (33, 55, 67)": makeTrial(new Psy.Blank({fill: "rgb(33,55,67)"}), SpaceOrTimeout5000)

  CanvasBorder:
    "Default": makeTrial(new Psy.CanvasBorder(), SpaceKey)
    "Blue Border": makeTrial(new Psy.CanvasBorder({stroke: "blue"}), SpaceKey)
    "Thick Blue Border": makeTrial(new Psy.CanvasBorder({stroke: "blue", strokeWidth: 20}), SpaceKey)

  GridLines:
    "Default GridLines": makeTrial(new Psy.GridLines(), SpaceKey)
    "5 X 5 GridLines": makeTrial(new Psy.GridLines({rows:5, cols:5}), SpaceKey)
    "5 X 5 Dashed GridLines": makeTrial(new Psy.GridLines({rows:5, cols:5, dashArray: [10,5]}), SpaceKey)

  Rectangle:
    "Default Rect": makeTrial(new Psy.Rectangle(), SpaceKey)
    "Green Square 500 by 500": makeTrial(new Psy.Rectangle({width: 500, height: 500, fill: "green"}), SpaceOrTimeout5000)
    "Green Square Blue Stroke": makeTrial(new Psy.Rectangle({width: 500, height: 500, fill: "green", stroke: "blue"}), SpaceOrTimeout5000)
    "Default Rect, x 50%, y 50%": makeTrial(new Psy.Rectangle({position: ["50%","50%"]}), SpaceKey)
    "Default Rect, grid 3,3 [0,0]": makeTrial(new Psy.Rectangle({position: [0,0], layout: new Psy.GridLayout(3,3, {x:0, y:0, width:800, height:800})}), SpaceKey)
    "Default Rect, grid 3,3 [2,2]": makeTrial(new Psy.Rectangle({position: [2,2], layout: new Psy.GridLayout(3,3, {x:0, y:0, width:stage.getWidth(), height:stage.getHeight()})}), SpaceKey)

  Circle:
    "Default Circle": makeTrial(new Psy.Circle(), SpaceKey)
    "Green Circle Radius 50": makeTrial(new Psy.Circle({radius: 50, fill: "green"}), SpaceOrTimeout5000)
    "Green Circle Blue Stroke": makeTrial(new Psy.Circle({radius: 50, fill: "green", stroke: "blue"}), SpaceOrTimeout5000)

  Arrow:
    "Default Arrow": makeTrial(new Psy.Arrow(), SpaceKey)
    "Blue Arrow, length 200": makeTrial(new Psy.Arrow({length: 200, fill: "blue"}), SpaceKey)
    "Blue Arrow, black stroke": makeTrial(new Psy.Arrow({length: 200, fill: "blue", stroke: "black", strokeWidth: 4}), SpaceKey)
    "Rotating Arrow": makeTrial(new Psy.Sequence(
      for i in [0 .. 360] by 2
        new Psy.Arrow({x:300, y:300, length: 200, fill: "black", angle: i})
      [40]), SpaceKey)
    "Rotating Arrow no clear": makeTrial(new Psy.Sequence(
      for i in [0 .. 360] by 2
        new Psy.Arrow({x:300, y:300, length: 200, fill: "black", angle: i, opacity: i/720})
      [40], clear=false), SpaceKey)

  Picture:
    "Default Picture": makeTrial(new Psy.Picture(), SpaceKey)
    "Default 300 X 300": makeTrial(new Psy.Picture({width: 300, height: 300}), SpaceKey)

  StartButton:
    "Start Button": makeTrial(new Psy.StartButton({id: "start"}), new Psy.ClickResponse("start"))

  Group:
    "Group of Circles": makeTrial(new Psy.Group(
      [ new Psy.Circle({x: 100, y: 150, radius:70 }),
        new Psy.Circle({x: 250, y: 150, radius:70 }),
        new Psy.Circle({x: 400, y: 150, radius:70 })]), SpaceKey)
    "Overlapping Circles": makeTrial(new Psy.Group(
      [ new Psy.Circle({x: 100, y: 150, radius:100, opacity:  1, fill: "red" }),
        new Psy.Circle({x: 250, y: 150, radius:100, opacity: .5, fill: "yellow" }),
        new Psy.Circle({x: 175, y: 250, radius:100, opacity: .5, fill: "blue" })]), SpaceKey)
    "Colored Squares": makeTrial(new Psy.Group(
      [ new Psy.Rectangle({x: 100, y: 50, width: 50, height: 50, fill: "red" }),
        new Psy.Rectangle({x: 250, y: 500, width: 50, height: 50, fill: "orange" }),
        new Psy.Rectangle({x: 200, y: 300, width: 50, height: 50, fill: "cyan" }),
        new Psy.Rectangle({x: 65,  y: 250, width: 50, height: 50, fill: "pink" })]), SpaceKey)
    "Colored Squares on Grid": makeTrial(new Psy.Group(
      [ new Psy.Rectangle({position: [0,0], width: 50, height: 50, fill: "red" }),
        new Psy.Rectangle({position: [2,2], width: 60, height: 60, fill: "orange" }),
        new Psy.Rectangle({position: [4,4], width: 70, height: 70, fill: "cyan"}),
        new Psy.Rectangle({position: [6,6], width: 80, height: 80, fill: "pink" })], gridlayout), SpaceKey)
    "VSTM Example Trial": genColoredSquareTrial()

  Sequence:
    "Count to Three": makeTrial(new Psy.Sequence(
      [ new Psy.Text({content: "One", position: "center"}),
        new Psy.Text({content: "Two", position: "center"}),
        new Psy.Text({content: "Three", position: "center"})],
      [1000, 2000, 4000]), SpaceKey)
    "Count to Three with Overlay": makeTrial(new Psy.Sequence(
      [ new Psy.Text({content: "One", position: "center-left"}),
        new Psy.Text({content: "Two", position: "center"}),
        new Psy.Text({content: "Three", position: "center-right"})],
      [1000, 2000, 4000], clear=false), SpaceKey)
    "Fast Countdown": makeTrial(new Psy.Sequence(
      for i in [50..0]
        r = i*4
        g = 255 - (i*4)
        b = i


        new Psy.Text({content: i, position: "center", fontSize: 80 + i*2, fill: "rgb(#{r},#{g},#{b})"})
      [80]), SpaceKey)
    "Repeating Squares": makeTrial(new Psy.Sequence(
      [ new Psy.Rectangle({position: [2,2], width: 80, height: 80, fill: "red", layout: gridlayout}),
        new Psy.Rectangle({position: [2,3], width: 80, height: 80, fill: "blue", layout: gridlayout}),
        new Psy.Rectangle({position: [2,4], width: 80, height: 80, fill: "yellow", layout: gridlayout})
      ], [100], true, 9), SpaceKey)


  Background:
    "Background fill": wrapEvents([
      new Psy.Event(new Psy.Text({content: "Hello,"}), Timeout1000),
      new Psy.Event(new Psy.Text({content: "How"}), Timeout1000),
      new Psy.Event(new Psy.Text({content: "are"}), Timeout1000),
      new Psy.Event(new Psy.Text({content: "you"}), Timeout1000),
      new Psy.Event(new Psy.Text({content: "Today"}), SpaceKey)],
      new Psy.Background([new Psy.Text({content: "I am a background stimulus", position: "bottom-center"})],  "red"))

  TextInput:
    "Default TextInput": makeTrial(new Psy.TextInput(), SpaceKey)
    "Larger Text Input": makeTrial(new Psy.TextInput({width: 300, height: 74}), SpaceKey)
    "Even Larger Text Input": makeTrial(new Psy.TextInput({width: 500, height: 150}), SpaceKey)
    "Gigantic Text Input": makeTrial(new Psy.TextInput({width: 800, height: 300}), SpaceKey)




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

    console.log(trial)
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

