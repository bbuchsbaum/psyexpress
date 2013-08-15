
_ = require('lodash')


asArray = (value) ->
  if (_.isArray(value))
    value
  else if (_.isNumber(value) or _.isBoolean(value))
    [value]
  else
    _.toArray(value)

#seqalong = (vec) -> [0 .. vec.length - 1]

rep = (vec, times) ->

  if not (times instanceof Array)
    times = [times]

  if (times.length != 1 and vec.length != times.length)
    console.log("vec", vec)
    console.log("times", times)
    throw "vec.length must equal times.length or times.length must be 1"
  if vec.length == times.length
    out = for el, i in vec
      for j in [1..times[i]]
        el
    _.flatten(out)
  else
    out = _.times(times[0], (n) => vec)
    _.flatten(out)



exports.rep = rep
#exports.seqalong = seqalong

# ## Sampler
# basic sampler that does not recycle its elements or allow sampling with replacement
exports.Sampler =
class Sampler

  constructor: (@items) ->

  take: (n) ->
    if n > @items.length
      throw "cannot take sample larger than the number of items when using non-replacing sampler"
    _.shuffle(@items)[0...n]


# ## ExhaustiveSampler
exports.ExhaustiveSampler =
class ExhaustiveSampler

  @fillBuffer: (items, n) ->
    buf = (_.shuffle(items) for i in [1..n])
    _.flatten(buf)

  constructor: (@items, buflen=10) ->
    @buffer = ExhaustiveSampler.fillBuffer(@items, buflen)


  take: (n) ->
    # the sampling strategy is **exhaustive**, which means that all items will be sampled once before any item is sampled twice.
    if n <= @buffer.length
      # if the number of requested items is less than or equal to the size of the buffer, return the next **n** items
      res = _.take(@buffer, n)
      @buffer = _.drop(@buffer, n)
      res
    else
      # otherwise, create a new buffer
      buflen = Math.max(n, 10*@items.length)
      buf = ExhaustiveSampler.fillBuffer(@items, buflen/@items.length)
      # place remaining items from previous buffer at head of the new buffer
      @buffer = @buffer.concat(buf)


# ## UniformSampler
exports.UniformSampler =
class UniformSampler extends Sampler

  @validate: (range) ->
    if (range.length != 2)
      throw "range must be an array with two values (min, max)"
    if (range[1] <= range[0])
      throw "range[1] must > range[0]"

  constructor: (@range) ->
    @interval = @range[1] - @range[0]

  take: (n) ->
    nums = (Math.round(Math.random()*@interval) for i in [1..n])
    nums

# ## ConditionalSampler
exports.ConditionalSampler =
class ConditionalSampler extends Sampler

  constructor: (@keyMap) ->
    @samplerSet = {}
    for key, value of @keyMap
      console.log("key: ", key)
      console.log("value: ", value)
      @samplerSet[key] = new ExhaustiveSampler(value)
    console.log(_.keys(@samplerSet))

  take: (n) ->

  take: (key, n) -> @samplerSet[key].take(n)


# ## Factor
exports.Factor =
class Factor extends Array

  @asFactor = (arr) ->  new Factor(arr...)

  constructor: (arr) ->
    @push arg for arg in arr
    @levels = _.uniq(arr).sort()

# ## DataTable
exports.DataTable =
class DataTable

  show: ->
    console.log("DataTable: rows: #{@nrow()} columns: #{@ncol()}")
    for i in [0...@nrow()]
      console.log(@record(i))

  @build: (vars={ }) -> Object.seal(new DataTable(vars))

  @expand: (vars={}, unique=true, nreps=1) ->
    if unique
      out = {}
      for name, value of vars
        out[name] = _.unique(value)
      vars=out

    nargs = _.size(vars)
    nm = _.keys(vars)
    repfac = 1
    d = _.map(vars, (x) -> x.length)

    orep = _.reduce(d, (x, acc) -> x*acc)
    out = {}
    for key, value of vars
      nx = value.length
      orep = orep/nx
      r1 = rep([repfac], nx)
      r2 = rep([0...nx], r1)
      r3 = rep(r2, orep)
      out[key] = (value[i] for i in r3)
      repfac = repfac * nx

    #if (nreps > 1)
    #  for i in [1..nreps]
    #    out = _.merge(out,out)


    new DataTable(out)

  constructor: (vars={ }) ->
    varlen = _.map(vars, (x) -> x.length)
    samelen = _.all(varlen, (x) -> x == varlen[0])

    if not samelen
      throw "arguments to DataTable must all have same length."

    for key, value of vars
      this[key] = value

  subset: (key, filter) ->
    keep = for val in this[key]
      if (filter(val)) then true else false
    out = {}

    for own name, value of this
      out[name] = (el for el, i in value when keep[i] == true)

    new DataTable(out)

  whichRow: (where) ->
    out = []
    nkeys = _.keys(where).length

    for i in [0...@nrow()]
      rec = @record(i)
      count = asArray(rec[key] == value for key, value of where)
      count = _.map(count, (x) -> if x then 1 else 0)
      count = _.reduce(asArray(count), (sum, num) -> sum + num)

      if count == nkeys
        out.push(i)

    out




  select: (where) ->
    out = []
    nkeys = _.keys(where).length

    for i in [0...@nrow()]
      rec = @record(i)
      count = asArray(rec[key] == value for key, value of where)
      count = _.map(count, (x) -> if x then 1 else 0)
      count = _.reduce(asArray(count), (sum, num) -> sum + num)

      if count == nkeys
        out.push(rec)

    out

  nrow: ->
    lens = (value.length for own name, value of this)
    _.max(lens)

  ncol: -> Object.keys(this).length

  colnames: -> Object.keys(this)

  record: (index) ->
    rec = {}
    for own name, value of this
      rec[name] = value[index]
    rec

  replicate: (nreps) ->
    out = {}
    for own name, value of this
      out[name] = _.flatten(_.times(nreps, (n) => value))
    new DataTable(out)

  bindcol: (name, column) ->
    if (column.length != @nrow())
     throw "new column must be same length as existing DataTable object: column.length is  #{column.length} and this.length is  #{@nrow()}"
    this[name] = column
    this

  bindrow: (rows) ->
    if (!_.isArray(rows))
      rows = [rows]
    for record in rows
      console.log(record)
      for own key, value of record
        if (!_.has(this, key))
          throw "DataTable has no field named #{key}"
        else
           this[key].push(value)
    this

# ## ItemSet
# A class that handles the sampling of experimental items
exports.ItemSet =
class ItemSet
#itemTable must be of type 'DataTable'
  constructor: (@items, @attributes, @samplerFactory) ->
    @attributeSet = DataTable.expand(@attributes, unique=true)
    @attributeSet.show()


exports.ExperimentContext =
class ExperimentContext
  @block = 0
  @trial = 0

exports.Experiment =
class Experiment
  constructor: (@designSpec) ->
    @design = new ExpDesign(@designSpec)

    @display = @designSpec["Display"]
    @trialGenerator = @display["Trial"]

    console.log(@display)


  start: (@context) ->
    #@context = new ExperimentContext(@stage)
    numBlocks =  @design.blocks
    trials = @design.blockTrials(0)
    console.log(trials.nrow())
    for i in [0 ... trials.nrow()]
      console.log(trials.record(i))
      trial = trials.record(i)
      gentrial = @trialGenerator(trial)
      #console.log(gentrial)

exports.VarSpec =
class VarSpec
  @name = ""
  @nblocks = 1
  @reps = 1
  @expanded = {}


  ntrials: -> @nblocks * @reps

  valueAt: (block, trial) ->

exports.FactorSpec =
class FactorSpec extends VarSpec

  constructor: (@nblocks, @reps, @name, @levels) ->
    @expanded = @expand(@nblocks, @reps)

  cross: (other) -> new CrossedFactorSpec(@nblocks, @reps, this, other)

  expand: (nblocks, reps) ->
    prop = {}
    prop[@name] = @levels
    vset = new DataTable(prop)
    vset.replicate(reps) for i in [1..nblocks]

  valueAt: (block, trial) -> @expanded[block][@name][trial]


exports.CrossedFactorSpec =
class CrossedFactorSpec extends VarSpec
  constructor: (@nblocks, @reps, @parents...) ->
    @parentNames = (fac.name for fac in @parents)
    @name = _.reduce(@parentNames, (n,n1) -> n + ":" + n1)
    @levels = (fac.levels for fac in @parents)
    @factorSet = _.zipObject(@parentNames, @levels)
    @table = DataTable.expand(@factorSet)
    @expanded = @expand(@nblocks, @reps)

  expand: (nblocks, reps) ->
    @table.replicate(reps) for i in [1..nblocks]

  valueAt: (block, trial) ->
    @expanded[block][name][trial] for name in @parentNames



# ## ExpDesign
# A class that represents an experimental design consisting of an array of one or more **blocks**
# each consisting of a set of one or more **trials**.
exports.ExpDesign =
class ExpDesign

  @blocks = 1


  blockTrials: (blocknum) ->
    @design[blocknum]

  ncells: (includeBlock=false) ->
    if (includeBlock)
      @crossedCells.nrow() * @blocks
    else
      @crossedCells.nrow()


  ntrials: (byBlock=false) ->
    blen = _.map(@design, (x) -> x.nrow())
    if (byBlock)
      blen
    else
      _.reduce(blen, (sum, num) -> sum + num)

  crossVariables: (vars) -> DataTable.expand(vars)

  @validate: (spec) ->
    if (!("Design" of spec))
      throw "Design is undefined"
    des = spec["Design"]

    if (!("Variables" of des))
      throw "Variables is undefined"
    if (!("Structure" of des))
      throw "Structure is undefined"
    if (!("Items" of spec))
      throw "Items is undefined"

  #@crossedItems: (itemSpec, varnames) ->
  #  vsort = varnames.sort().join(',')
  #  res = _.filter(itemSpec, (item) -> item["variables"].sort().join(',') == vsort)
    # assumes we have only one set of crossed items ....
  #  res[0]

  @expandBlocks: (nblocks, reps, vars...) ->
    res = for vset in vars
      (vset.replicate(reps) for i in [1..nblocks])

    console.log(res)



  @splitCrossedItems: (itemSpec, crossedVariables) ->
    ## TODO must check that item section contains these variables
    attrnames = crossedVariables.colnames()


    keySet = for i in [0...crossedVariables.nrow()]
      record = crossedVariables.record(i)
      levs = _.values(record)
      _.reduce(levs, ((a, b) -> a + ":" + b))


    values = itemSpec["values"]

    conditionTable = new DataTable(_.pick(itemSpec, attrnames))

    itemSets = for i in [0...crossedVariables.nrow()]
      record = crossedVariables.record(i)
      indices = conditionTable.whichRow(record)
      values[j] for j in indices


    _.zipObject(keySet, itemSets)


  @makeSampler: () ->
    # given a Data


  getCrossedVars: (@variables) ->
    crossed = @variables["Crossed"]
    crossedVars = {}
    crossedVars[key] = value["levels"] for key, value of crossed when value["type"] is "Factor"
    crossedVars


  constructor: (spec={ }) ->
    ## validate format of spec structure
    ExpDesign.validate(spec)


    @design = spec["Design"]

    @variables = @design["Variables"]

    @itemSpec = spec["Items"]

    console.log("creating design")

    @structure = @design["Structure"]

    @varnames = _.keys(@variables)

    @crossed = @variables["Crossed"]

    @auxiliary = @variables["Auxiliary"]

    @crossedVars = @getCrossedVars(@variables)

    @crossedCells = @crossVariables(@crossedVars)

    crossedItems = @itemSpec["Crossed"]

    crossedItemName = _.keys(crossedItems)[0]

    crossedItemSets = ExpDesign.splitCrossedItems(crossedItems[crossedItemName], @crossedCells)

    @crossedSampler = new ConditionalSampler(crossedItemSets)

    console.log(@crossedSampler.take("word:1", 32))


    if (@structure["type"] == "Block")
      if (!_.has(@structure, "reps_per_block"))
        @structure["reps_per_block"] = 1

      reps = @structure["reps_per_block"]

      @blocks = @structure["blocks"]

      #@crossedDesign = (@crossedCells.replicate(reps) for i in [1..@blocks])
      @x = ExpDesign.expandBlocks(@blocks, reps, @crossedCells)
      console.log(@x)

    # need a structure that encapsulates crossed and uncrossed variables and can sample them
    # 1. each variable or variable combination is first expanded
    # 2. following expansion, it is placed in a key value data structure, where the key is the variable name/combination and the value is the condition
    # 3. Conditional Sampler could "know" about the conditional design, so that "take" extracts the correct value-pair.
    # 4. This array of samplers is used to generate the items. The items then are bound back in to the experimental design.

    console.log(@crossedDesign)


#dt = new DataTable({x: [1,2,3,4,5,2,1], y: ['a', 'b', 'b', 'c', 'd', 'e', 'a']})
#res = dt.select({y: 'b'})
#console.log(res)

#dt2 = dt.bindrow([{x: 26, y: 'u'}, {x:66, y:88}])
#dt2.show()

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

      Auxiliary:
        isi:
          type: "Continuous"


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

    Auxiliary:
      isi:
        sampler:
          type: "Uniform"
          min: 300
          max: 3000



  Display:
    Trial: (trial) ->
      #console.log(trial)
      1:
        FixationCross: length: 100, strokeWidth: 5
        Next:
          Timeout: trial.isi
      2:
        Text:
          x:0, y:0, content: trial.word
        Next:
          KeyPressed:
            keys: ['a', 'b']
            correct: if trial.wordtype is "word" then 'a' else 'b'
            maxDuration: 3000
            minDuration: 500

#exp = new ExpDesign(@LexDesign)
#console.log(exp)
#exp = new Experiment(@LexDesign)
#console.log(exp)
#exp.start(new ExperimentContext())

#x = new DataTable({ x: [1,2,3], y: [3,4,5]})

f1 = new FactorSpec(5,3,"wordtype", ["word", "nonword"])
f2 = new FactorSpec(5,3,"syllables", [1, 2])
f3 = f1.cross(f2)
#console.log(f3.names)
#console.log(f3.levels)
#console.log(f3.table)
#console.log(f1.expand(5,5))
console.log(f3.expanded)
console.log(f1.ntrials())
console.log(f3.valueAt(1,3))