

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

@makeTrial = (stim, resp, bg=new Psy.Background([], fill= "gray")) ->
  new Psy.Trial([new Psy.Event(stim, resp), ClearEvent], {}, bg)

@wrapEvents = (events, bg=new Psy.Background([], fill= "white")) ->
  new Psy.Trial(events.concat(ClearEvent), {}, bg)


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

  Rectangle:
    "Default Rect": makeTrial(new Psy.Rectangle(), SpaceKey)
    "Green Square 500 by 500": makeTrial(new Psy.Rectangle({width: 500, height: 500, fill: "green"}), SpaceOrTimeout5000)
    "Green Square Blue Stroke": makeTrial(new Psy.Rectangle({width: 500, height: 500, fill: "green", stroke: "blue"}), SpaceOrTimeout5000)

  Circle:
    "Default Circle": makeTrial(new Psy.Circle(), SpaceKey)
    "Green Circle Radius 50": makeTrial(new Psy.Circle({radius: 50, fill: "green"}), SpaceOrTimeout5000)
    "Green Circle Blue Stroke": makeTrial(new Psy.Circle({radius: 50, fill: "green", stroke: "blue"}), SpaceOrTimeout5000)

  Arrow:
    "Default Arrow": makeTrial(new Psy.Arrow(), SpaceKey)
    "Blue Arrow, length 200": makeTrial(new Psy.Arrow({length: 200, fill: "blue"}), SpaceKey)
    "Rotating Arrow": makeTrial(new Psy.Sequence(
      for i in [0..50]
        new Psy.Arrow({length: 200, fill: "blue", angle: i})
      [80]), SpaceKey)

  Picture:
    "Default Picture": makeTrial(new Psy.Picture(), SpaceKey)
    "Default 300 X 300": makeTrial(new Psy.Picture({width: 300, height: 300}), SpaceKey)

  StartButton:
    "Start Button": makeTrial(new Psy.StartButton({id: "start"}), new Psy.ClickResponse("start"))

  Group:
    "Group of Circles": makeTrial(new Psy.Group(
      [ new Psy.Circle({x: 100, y: 150, radius:25 }),
        new Psy.Circle({x: 250, y: 150, radius:45 }),
        new Psy.Circle({x: 400, y: 150, radius:65 })]), SpaceKey)
    "Colored Squares": makeTrial(new Psy.Group(
      [ new Psy.Rectangle({x: 100, y: 50, width: 50, height: 50, fill: "red" }),
        new Psy.Rectangle({x: 250, y: 500, width: 50, height: 50, fill: "orange" }),
        new Psy.Rectangle({x: 200, y: 300, width: 50, height: 50, fill: "cyan" }),
        new Psy.Rectangle({x: 65,  y: 250, width: 50, height: 50, fill: "pink" })]), SpaceKey)

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
      [1000, 2000, 4000], overlay=true), SpaceKey)
    "Fast Countdown": makeTrial(new Psy.Sequence(
      for i in [50..0]
        new Psy.Text({content: i, position: "center", fontSize: 80})
      [80]), SpaceKey)

  Background:
    "Background fill": wrapEvents([
      new Psy.Event(new Psy.Text({content: "Hello,"}), Timeout1000),
      new Psy.Event(new Psy.Text({content: "How"}), Timeout1000),
      new Psy.Event(new Psy.Text({content: "are"}), Timeout1000),
      new Psy.Event(new Psy.Text({content: "you"}), Timeout1000),
      new Psy.Event(new Psy.Text({content: "Today"}), SpaceKey)],
      new Psy.Background([new Psy.Text({content: "I am a background stimulus", position: "bottom-center"})],  "red"))






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
    console.log(trial)
    trial.start(context)


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

