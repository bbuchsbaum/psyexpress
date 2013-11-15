


stage = new Kinetic.Stage({
  container: 'container'
  width: $(window).width() * 0.95
  height: $(window).height() * 0.95
})



context = new Psy.KineticContext(stage)
factory = new Psy.KineticStimFactory()


clrs = ["red", "orange", "purple", "brown", "white", "black", "darkblue", "lightblue",  "yellow", "pink", "darkgreen", "lightgreen"]

factorSet =
  probe:
    levels: ["match", "mismatch"]
  load:
    levels: [1,2,3]

@coordSampler = new Psy.GridSampler([2,3,4], [2,3,4])
@colorSampler = new Psy.ExhaustiveSampler(clrs)

window.display =
  Display:
    Trial: (trial) =>

      pos = coordSampler.take(trial.load)
      colors = colorSampler.take(trial.load)

      probeIndex = Psy.sample([0...trial.load], 1)
      probePos = pos[probeIndex]

      if trial.probe is "match"
        probeColor = colors[probeIndex]
      else
        setdiff = _.difference(clrs, [colors[probeIndex]])
        console.log("setdiff is", setdiff)
        console.log("all colors", clrs)
        probeColor = Psy.sample(setdiff,1)[0]


      console.log("probe color", probeColor)
      console.log("trial.probe", trial.probe)
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
          Clear:
            x: 0
          Next:
            Timeout:
              duration: 800
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
              timeout: 3000






fnode = Psy.FactorSetNode.build(factorSet)
window.trials = fnode.trialList(5, 5)
window.trials.shuffle()

window.iter = trials.blockIterator()

console.log("trials", trials)
window.pres = new Psy.Presenter(trials, display.Display, factory)
console.log("pres", pres)
pres.start(context)

#exp = new Psy.Experiment(@LexDesign, factory)
#exp.start(context)



