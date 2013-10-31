


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
    levels: [1,2,3,4,5,6]

fnode = Psy.FactorSetNode.build(factorSet)
window.trials = fnode.trialList(5, 5)
window.trials.shuffle()

window.iter = trials.blockIterator()

console.log("trials", trials)
window.pres = new Psy.Presenter(trials, null, factory)
console.log("pres", pres)
pres.start(context)

#exp = new Psy.Experiment(@LexDesign, factory)
#exp.start(context)



