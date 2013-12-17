class MultipleChoice extends Stimulus

  defaults:
    question: "What is your name?", options: ["Bill", "John", "Fred"], x: 10, y: 10, fill: "black", fontSize: 24, fontFamily: "Arial", textAlign: "center", position: null


  constructor: (spec) ->
    super(spec)
    @questionText = new Kinetic.Text({
      x: @spec.x
      y: @spec.y
      text: @spec.question
      fontSize: @spec.fontSize
      fontFamily: @spec.fontFamily
      fill: @spec.fill
    })

    @choices = for i in [0...@spec.options.length]
      new Kinetic.Text({
        x: @spec.x + 5
        y: questionText.getHeight() * (i + 1) + 30
        text: (i + 1) + ") " + @spec.options[i]
        fontSize: @spec.fontSize
        fontFamily: @spec.fontFamily
        fill: @spec.fill
        padding: 20
        align: 'left'
      })

  render: (context, layer) ->
    layer.add(@questionText)
    for i in [0...@choices.length]
      layer.add(@choices[i])


exports.MultipleChoice = MultipleChoice