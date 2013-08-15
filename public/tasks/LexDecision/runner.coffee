

#canvas = new fabric.Canvas('c')
stage = new Kinetic.Stage({
  container: 'container',
  width: $(window).width() * .95,
  height: $(window).height() * .95
})

#console.log(stage)
console.log("width", $(document).width())

context = new Psy.KineticContext(stage)
resp1 = new Psy.KeypressResponse(['a', 'b'])
resp2 = new Psy.MousepressResponse()
#resp3 = new Psy.Prompt title: "Hiya!", delay: 2500, defaultValue: "whatup"
#resp3 = new Psy.TypedResponse()
resp3 = new Psy.MousepressResponse()
resp4 = new Psy.MousepressResponse()
resp5 = new Psy.Timeout(5000)
word1 = new Psy.Text({content: "Hello", x: stage.getWidth()/2, y: stage.getHeight()/2, fill: "black", fontSize: 20})
word2 = new Psy.Text({content: "Charlie", x: stage.getWidth()/2, y: stage.getHeight()/2, fill: "black", fontSize: 80})
fixcross = new Psy.FixationCross({strokeWidth: 10, length: 200})
word3 = new Psy.Text({content: "Bye", x: stage.getWidth()/2, y: stage.getHeight()/2, fill: "black", fontSize: 200})
border = new Psy.CanvasBorder({strokeWidth: 8, stroke: "green"})

event1 = new Psy.Event(word1, resp2)
event2 = new Psy.Event(word2, resp3)
event3 = new Psy.Event(fixcross, resp4)
event4 = new Psy.Event(word3, resp1)
event5 = new Psy.Event(border, resp5)
event6 = new Psy.Event(new Psy.Sound("/tasks/LexDecision/resources/pa.3.4.mp3"), new Psy.Timeout(2000))
event7 = new Psy.Event(new Psy.StartButton(), resp2)

trial = new Psy.Trial([event7, event3, event2, event1, event4, event5, event6, event1])
trial.start(context)

