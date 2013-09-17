
@LexDesign =

  Design:
    Variables:
      Crossed:
        wordtype:
          type: "Factor"
          levels: ["word","nonword"]

        syllables:
          type: "Factor"
          levels: [1, 2]

  #Auxiliary:
  #  isi:
  #    type: "Continuous"

    Structure:
      type: "Block"
      blocks: 8
      reps_per_block: 4


  Items:
    Crossed:
      words:
        values: ["hello", "goodbye", "flirg", "schmirt", "black", "sweetheart", "grum", "snirg", "snake", "pet", "hirble", "kerble"]

        wordtype: ["word", "word", "nonword", "nonword", "word", "word", "nonword", "nonword", "word", "word", "nonword", "nonword"]

        syllables: [2,2,1,1,1,2,1,1,1,1,2,2]

        sampler:
          type: "Exhaustive"

#Auxiliary:
#  isi:
#    sampler:
#      type: "Uniform"
#      min: 300
#      max: 3000



  Display:
    Trial: (trial) ->
      #console.log(trial)
      1:
        FixationCross: length: 100, strokeWidth: 5
        Next:
          Timeout:
            duration: 2000
      2:
        Text:
          content: trial.words, position: "center"
        Next:
          KeyPressed:
            keys: ['a', 'b']
            correct: if trial.wordtype is "word" then 'a' else 'b'
            timeout: 3000