


stage = new Kinetic.Stage({
  container: 'container'
  width: 900
  height: 800
})


context = new Psy.KineticContext(stage)



clrs = ["red", "orange", "purple", "brown", "black", "darkblue", "lightblue",  "yellow", "pink", "darkgreen", "lightgreen"]

factorSet =
  probe:
    levels: ["match", "mismatch"]
  load:
    levels: [1,2,3]

@coordSampler = new Psy.GridSampler([2,3,4], [2,3,4])
@colorSampler = new Psy.ExhaustiveSampler(clrs)

window.display =
  Display:
    Prelude:
      Instructions:
        pages:
          1:
            MarkDown: """

          Welcome to the Experiment!
          ==========================

          This is a test of visual short-term memory.

          On every trial a number of colored squares will be briefly presented on the screen.
          Try to remember their colors. After the set of squares dissappear, a single 'probe'
          square will appear at one the locations previously occupied by one of the
          squares. You will have to decide whether the 'probe' square is the same color as the square
          that previously occupied the same spatial location.

            * If the probe square is the same color ( a match), press the 'n' key.

            * If the probe square is a different color ( a non match), press the 'm' key.

            * If your response is correct, you will will get a "Correct!" message, otherwise you will get an "Incorrect!" message.

          """


    Block:
      Start: (context) ->
        console.log("context", context)
        Text:
          position: "center"
          content: ["Get Ready!", "Press Space Bar to start"]
        Next:
          SpaceKey: ""

      End: (context) ->
        console.log("context", context)
        console.log("responses", context.eventData.findAll("probeResponse"))
        Text:
          position: "center"
          content: ["End of Block", "Press Space Bar to continue to next block"]
        Next:
          SpaceKey: ""

    Trial: (trial) =>

      pos = coordSampler.take(trial.load)
      colors = colorSampler.take(trial.load)

      probeIndex = Psy.sample([0...trial.load], 1)
      probePos = pos[probeIndex]

      if trial.probe is "match"
        probeColor = colors[probeIndex]
      else
        setdiff = _.difference(clrs, [colors[probeIndex]])
        probeColor = Psy.sample(setdiff,1)[0]


      Events:
        1:
          FixationCross: length: 100, strokeWidth: 5
          Next:
            Timeout:
              duration: 800
        2:
          Group:
            stims:
              for i in [0...pos.length]
                Rectangle:
                  position: pos[i]
                  width: 50
                  height: 50
                  fill: colors[i]
            layout:
              Grid: [7, 7]
          Next:
            Timeout:
              duration: 1500
        3:
          Clear: 0

          Next:
            Timeout:
              duration: 1500
        4:
          Group:
            stims:
              [
                Rectangle:
                  position: probePos
                  width: 50
                  height: 50
                  fill: probeColor
              ]
            layout:
              Grid: [7,7]

          Next:
            KeyPress:
              id: "probeResponse"
              keys: ['n', 'm']
              correct: if trial.probe is "match" then 'n' else 'm'
              #timeout: 3000

      Feedback: (eventStack) ->
        ev = eventStack.last()
        HtmlIcon:
          glyph: if ev.Accuracy is true then "checkmark" else "frown"
          size: "massive"
          x: "50%"
          y: "50%"
          #fill: if ev.Accuracy then "green" else "red"
          #position: "center"
        Next:
          Timeout:
            duration: 1500








fnode = Psy.FactorSetNode.build(factorSet)
window.trials = fnode.trialList(5, 1)
window.trials.shuffle()

window.iter = trials.blockIterator()

console.log("trials", trials)
try
  window.pres = new Psy.Presenter(trials, display.Display, context, context.stimFactory)
  console.log("pres", pres)
  pres.start()
catch error
  console.log("Caught error", error.name, " ", error.message)

#exp = new Psy.Experiment(@LexDesign, factory)
#exp.start(context)



