

@LexDesign =

  Variables:
    wordtype:
      type: "Factor"
      levels: ["word","nonword"]
      crossed:  true

    syllables:
      type: "Factor"
      levels: [1, 2]
      crossed: true
    isi:
      type: "Continuous"
      range: [200, 3000]
      distribution: "Uniform"

  Structure:
    type: "Block"
    blocks: 8
    reps_per_block: 4

  Items:
    word:
      values: ["hello", "goodbye", "flirg", "schmirt", "black", "sweetheart", "grum", "snirg", "snake", "pet", "hirble", "kerble"]

      attributes:
        wordtype: ["word", "word", "nonword", "nonword", "word", "word", "nonword", "nonword", "word", "word", "nonword", "nonword"]
        syllables: [2,2,1,1,1,2,1,1,1,1,2,2]

      sampler:
        type: "Exhaustive"

@LexTask =
  Default: (trial) ->
    1:
      Blank: background: "white"
      Next:
        Timeout: trial.isi
    2:
      Text:
        x:0, y:0, content: trial.word
      Next:
        KeyPressed:
          keys: ['a', 'b']
          correct: if trial.wordtype is "word" then 'a' else 'b'


  #"wordtype{word}:syllable{1}": (trial) ->
  #  console.log(trial.isi)


#console.log(LexTask)
#console.log(Psy.rep([4,5,6], 7))