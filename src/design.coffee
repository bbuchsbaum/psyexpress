_ = require('lodash')
utils = require("./utils")
DataTable = require("./datatable").DataTable


# ## Factor
exports.Factor =
  class Factor extends Array

    @asFactor = (arr) ->
      new Factor(arr...)

    constructor: (arr) ->
      @push arg for arg in arr
      @levels = _.uniq(arr).sort()


exports.VarSpec =
  class VarSpec
    @name = ""
    @nblocks = 1
    @reps = 1
    @expanded = {}

    names: -> @name

    ntrials: ->
      @nblocks * @reps

    valueAt: (block, trial) ->



exports.FactorSpec =
  class FactorSpec extends VarSpec

    constructor: (@name, @levels) ->
      @factorSet = {}
      @factorSet[@name] = @levels
      @conditionTable = DataTable.expand(@factorSet)

    cross: (other) ->
      new CrossedFactorSpec(@nblocks, @reps, [this, other])

    #levels: -> @levels

    expand: (nblocks, reps) ->
      prop = {}
      prop[@name] = @levels
      vset = new DataTable(prop)

      blocks = for i in [1..nblocks]
        vset.replicate(reps)
      concatBlocks = _.reduce(blocks, (sum, nex) -> DataTable.rbind(sum, nex))
      concatBlocks.bindcol("$Block", utils.rep([1..nblocks], utils.rep(reps * vset.nrow(), nblocks)))
      concatBlocks


exports.CellTable =
  class CellTable extends VarSpec
    constructor: ( @parents) ->
      @parentNames = (fac.name for fac in @parents)
      @name = _.reduce(@parentNames, (n, n1) -> n + ":" + n1)
      @levels = (fac.levels for fac in @parents)
      @factorSet = _.zipObject(@parentNames, @levels)
      @table = DataTable.expand(@factorSet)
    #@expanded = @expand(@nblocks, @reps)

    names: -> @parentNames


    conditions: ->
      for i in [0...@table.nrow()]
        rec = @table.record(i)
        _.reduce(rec, (n,n1) -> n + ":" + n1)


    expand: (nblocks, reps) ->
      blocks = for i in [1..nblocks]
        @table.replicate(reps)


exports.TaskNode =
  class TaskNode
    constructor: (@varSpecs, @crossedSet=[]) ->
      # extract name of each variable
      @factorNames = _.map(@varSpecs, (x) -> x.names())

      # store names and variables in object
      @varmap = {}
      for i in [0...@factorNames.length]
        @varmap[@factorNames[i]] = @varSpecs[i]

      if (@crossedSet.length > 0)
        @crossedVars = @varmap[vname] for vname in @crossedSet
        @crossedSpec = new CrossedFactorSpec(@crossedVars)
      else
        @crossedVars = []
        @crossedSpec = {}

      @uncrossedVars = _.difference(@factorNames, @crossedSet)
      @uncrossedSpec = @varmap[vname] for vname in @uncrossedVars

      expand: (nblocks, nreps) ->
        if @crossedVars.length > 0
          ctable = @crossedSpec.expand(nblocks, nreps)



exports.FactorNode =
  class FactorNode

    @build: (name, spec) ->
      new FactorNode(name, spec.levels)

    constructor: (@name, @levels) ->
      @cellTable = new CellTable([this])


exports.FactorSetNode =
  class FactorSetNode

    @build: (spec) ->
      fnodes = for key, value of spec
        FactorNode.build(key, value)

      new FactorSetNode(fnodes)

    constructor: (@factors) ->
      @factorNames = _.map(@factors, (x) -> x.name)
      @varmap = {}
      for i in [0...@factorNames.length]
        @varmap[@factorNames[i]] = @factors[i]

      @cellTable = new CellTable(@factors)
      @name = @cellTable.name

    levels: -> @cellTable.levels

    conditions: -> @cellTable.conditions()

    expand: (nblocks, nreps) -> @cellTable.expand(nblocks, nreps)

    trialList: (nblocks=1, nreps=1) ->
      blocks = @expand(nblocks, nreps)
      tlist = new TrialList(nblocks)
      for i in [0...blocks.length]
        blk = blocks[i]
        for j in [0...blk.nrow()]
          tlist.add(i, blk.record(j))
      tlist

exports.Iterator =
  class Iterator

    hasNext: -> false
    next: -> throw "empty iterator"
    map: (fun) -> throw "empty iterator"

exports.ArrayIterator =
  class ArrayIterator extends Iterator
    constructor: (@arr) ->
      @cursor = 0

      hasNext: -> @cursor < @arr.length

      next: ->
        ret = @arr[@cursor]
        @cursor = @cursor + 1
        ret

      map: (f) -> _.map(@arr, (el) -> f(el))


exports.TrialList =
  class TrialList

    constructor: (nblocks) ->
      @blocks = []
      @blocks.push([]) for i in [0...nblocks]

    add: (block, trial, type="main") ->
      #if (block >= @blocks.length)
      #blen = @blocks.length
      #throw "block argument #{block} exceeds number of blocks in TrialList #{blen}"

      trial.$TYPE = type
      @blocks[block].push(trial)

    get: (block, trialNum) ->
      @blocks[block][trialNum]

    getBlock: (block) ->
      @blocks[block]

    ntrials: ->
      nt = _.map(@blocks, (b) -> b.length)
      _.reduce(nt, (x0,x1) -> x0 + x1)

    shuffle: ->
      @blocks = _.map(@blocks, (blk) -> _.shuffle(blk))

    blockIterator: -> new ArrayIterator(_.map(@blocks, (blk) -> new ArrayIterator(blk)))



exports.ItemNode =
  class ItemNode

    @build: (name, spec) ->
      attrs = new DataTable(spec.attributes)
      new ItemNode(name, spec.items, attrs, spec.type)

    constructor: (@name, @items, @attributes, @type) ->
      if @items.length != @attributes.nrow()
        throw "Number of items must equal number of attributes"


exports.VariablesNode =
  class VariablesNode

    constructor: (@variables=[], @crossed=[]) ->


exports.TaskSchema =
  class TaskSchema

    @build: (spec) ->
      schema= {}
      for key, value of spec
        schema[key] = FactorSetNode.build(value)

      new TaskSchema(schema)

    constructor: (@schema) ->

    trialTypes: -> _.keys(@schema)

    factors: (type) -> @schema[type]

# ## ExpDesign
# A class that represents an experimental design consisting of an array of one or more **blocks**
# each consisting of a set of one or more **trials**.
exports.ExpDesign =
  class ExpDesign

    @blocks = 1


    #blockTrials: (blocknum) ->
    #  @design[blocknum]

    #ncells: (includeBlock=false) ->
    #  if (includeBlock)
    #    @crossedCells.nrow() * @blocks
    #  else
    #    @crossedCells.nrow()


    #ntrials: (byBlock=false) ->
    #  blen = _.map(@design, (x) -> x.nrow())
    #  if (byBlock)
    #    blen
    #  else
    #    _.reduce(blen, (sum, num) -> sum + num)

    #crossVariables: (vars) -> DataTable.expand(vars)

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



    init: (spec) ->
      @design = spec["Design"]

      @variables = @design["Variables"]

      @itemSpec = spec["Items"]

      @structure = @design["Structure"]

      @factorNames = _.keys(@variables)

      @crossed = @variables["Crossed"]

      @auxiliary = @variables["Auxiliary"]

    initStructure: ->
      if (@structure["type"] == "Block")
        if (!_.has(@structure, "reps_per_block"))
          @structure["reps_per_block"] = 1

        @reps_per_block = @structure["reps_per_block"]

        @blocks = @structure["blocks"]
      else
        @reps_per_block = 1
        @blocks = 1


    makeConditionalSampler: (crossedSpec, crossedItems) ->
      crossedItemName = _.keys(crossedItems)[0]
      console.log("names:", crossedSpec.names())
      crossedItemMap = (crossedItems[crossedItemName][key] for key in crossedSpec.names())
      crossedItemMap = _.zipObject(_.keys(@crossed), crossedItemMap)
      console.log("item map: ", crossedItemMap)
      new ConditionalSampler(crossedItems[crossedItemName].values, new DataTable(crossedItemMap), crossedSpec)

    makeCrossedSpec: (crossed, nblocks, nreps) ->
      factors = for key, val of crossed
        new FactorSpec(nblocks, nreps, key, val.levels)

      crossed = new CrossedFactorSpec(nblocks, nreps, factors)

    makeFactorSpec: (fac, nblocks, nreps) ->
      new FactorSpec(nblocks, nreps, _.keys(fac)[0], _.values(fac)[0])


    constructor: (spec = {}) ->
      ## validate format of spec structure
      ExpDesign.validate(spec)
      @init(spec)
      @initStructure()

      @crossedSpec = @makeCrossedSpec(@crossed, @blocks, @reps_per_block)
      crossedItems = @itemSpec.Crossed

      crossedSampler = @makeConditionalSampler(@crossedSpec, crossedItems)

      @fullDesign = @crossedSpec.expanded.bindcol(_.keys(crossedItems)[0], crossedSampler.take(@crossedSpec.expanded.nrow()))

      console.log(@crossedDesign)

