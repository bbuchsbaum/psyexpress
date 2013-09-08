


stage = new Kinetic.Stage({
  container: 'container',
  width: $(window).width() * .95,
  height: $(window).height() * .95
})


console.log("width", $(document).width())

context = new Psy.KineticContext(stage)
factory = new Psy.KineticStimFactory()
console.log(@LexDesign)

exp = new Psy.Experiment(@LexDesign, factory)
exp.start(context)

