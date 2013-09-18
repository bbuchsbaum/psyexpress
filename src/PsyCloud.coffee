_ = require('lodash')
Q = require("q")

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
    out = _.times(times[0], (n) =>
      vec)
    _.flatten(out)

repLen = (vec, length) ->
  if (length < 1)
    throw "repLen: length must be greater than or equal to 1"

  for i in [0...length]
    vec[i % vec.length]


exports.rep = rep
exports.repLen = repLen
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

    constructor: (@items, buflen = 10) ->
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
        buflen = Math.max(n, 10 * @items.length)
        buf = ExhaustiveSampler.fillBuffer(@items, buflen / @items.length)
        # place remaining items from previous buffer at head of the new buffer
        @buffer = @buffer.concat(buf)
        @take(n)

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
      nums = (Math.round(Math.random() * @interval) for i in [1..n])
      nums


# ## Factor
exports.Factor =
  class Factor extends Array

    @asFactor = (arr) ->
      new Factor(arr...)

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

    @fromRecords: (records, union=true) ->
      allkeys = _.uniq(_.flatten(_.map(records, (rec) -> _.keys(rec))))
      console.log(allkeys)
      vars = {}
      for key in allkeys
        vars[key] = []
      console.log(vars)

      for rec in records
        for key in allkeys
          vars[key].push(rec[key] or null)
      new DataTable(vars)



    @build: (vars = {}) ->
      Object.seal(new DataTable(vars))

    @rbind: (tab1, tab2, union=false) ->
      keys1 = _.keys(tab1)
      keys2 = _.keys(tab2)
      sharedKeys =
        if union
          _.union(keys1, keys2)
        else
          _.intersection(keys1, keys2)

      console.log("shared keys", sharedKeys)

      out = {}
      for name in sharedKeys
        col1 = tab1[name]
        col2 = tab2[name]

        if not col1
          col1 = repLen([null], tab1.nrow())
        if not col2
          col2 = repLen([null], tab2.nrow())

        out[name] = col1.concat(col2)

      new DataTable(out)

    @cbind: (tab1, tab2) ->
      if (tab1.nrow() != tab2.nrow())
        throw "cbind requires arguments to have same number of rows"

      out = _.cloneDeep(tab1)
      diffkeys = _.difference(_.keys(tab2), _.keys(tab1))
      for key in diffkeys
        out[key] = tab2[key]

      out


    @expand: (vars = {}, unique = true, nreps = 1) ->
      if unique
        out = {}
        for name, value of vars
          out[name] = _.unique(value)
        vars = out

      nargs = _.size(vars)
      nm = _.keys(vars)
      repfac = 1
      d = _.map(vars, (x) ->
        x.length)

      orep = _.reduce(d, (x, acc) ->
        x * acc)
      out = {}
      for key, value of vars
        nx = value.length
        orep = orep / nx
        r1 = rep([repfac], nx)
        r2 = rep([0...nx], r1)
        r3 = rep(r2, orep)
        out[key] = (value[i] for i in r3)
        repfac = repfac * nx

      #if (nreps > 1)
      #  for i in [1..nreps]
      #    out = _.merge(out,out)


      new DataTable(out)

    constructor: (vars = {}) ->
      varlen = _.map(vars, (x) ->
        x.length)
      samelen = _.all(varlen, (x) ->
        x == varlen[0])

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
        count = _.reduce(asArray(count), (sum, num) ->
          sum + num)

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
        count = _.reduce(asArray(count), (sum, num) ->
          sum + num)

        if count == nkeys
          out.push(rec)

      out

    nrow: ->
      lens = (value.length for own name, value of this)
      _.max(lens)

    ncol: ->
      Object.keys(this).length

    colnames: ->
      Object.keys(this)

    record: (index) ->
      rec = {}
      for own name, value of this
        rec[name] = value[index]
      rec

    replicate: (nreps) ->
      out = {}
      for own name, value of this
        out[name] = _.flatten(_.times(nreps, (n) =>
          value))
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


exports.StimFactory =
  class StimFactory
    makeStimulus: (name, params) ->

    makeResponse: (name, params) ->

    makeEvent: (stim, response) ->


exports.MockStimFactory =
  class MockStimFactory extends StimFactory
    makeStimulus: (name, params) ->
      ret = {}
      ret[name] = params
      ret

    makeResponse: (name, params) ->
      ret = {}
      ret[name] = params
      ret

    makeEvent: (stim, response) ->
      [stim, response]



exports.Event =
  class Event

    constructor: (@stimulus, @response) ->

    start: (context) ->
      console.log("starting event", @stimulus)
      ## clear layer

      if not @stimulus.overlay
        context.clearContent()

      console.log("rendering event")

      ## render stimulus
      @stimulus.render(context, context.contentLayer)

      context.draw()

      console.log("activating response")
      ## activate response

      @response.activate(context).then((ret) =>
        ##
        @stimulus.stop()
        ret)


exports.Trial =
  class Trial
    constructor: (@events = [], @meta={}, @background) ->

    numEvents: ->
      @events.length

    push: (event) -> @events.push(event)

    start: (context) ->
      console.log("starting trial")
      context.clearBackground()

      if @background
        context.setBackground(@background)
        context.drawBackground()


      farray = _.map(@events, (ev) => (=> ev.start(context)))
      result = Q.resolve(0)

      for fun in farray
        result = result.then(fun)
      result

exports.ExperimentContext =
  class ExperimentContext
    eventLog: []

    trialNumber: 0

    currentTrial: {}

    logEvent: (key, value) ->
      console.log("logging event")
      record = _.clone(@currentTrial.meta)
      record[key] = value
      @eventLog.push(record)
      console.log(@eventLog)



    start: (trialList) ->
      funList = _.map(trialList, (trial) => (=>
        @trialNumber += 1
        @currentTrial = trial
        trial.start(this)))



      result = Q.resolve(0)

      for fun in funList
        console.log("building trial list")
        result = result.then(fun)
      #result.done()


    clearContent: ->

    clearBackground: ->

    keydownStream: -> #Bacon.fromEventTarget(window, "keydown")

    keypressStream: -> #Bacon.fromEventTarget(window, "keypress")

    mousepressStream: ->

    draw: ->


# Experiment
# has N parts
# with N blocks
# with N trials

exports.Experiment =
  class Experiment

    #@create: (designSpec, renderer = "Kinetic") ->
    #  switch renderer
    #    when "Kinetic" then new Experiment(designSpec)

    constructor: (@designSpec, @stimFactory = new MockStimFactory()) ->
      @design = new ExpDesign(@designSpec)

      @display = @designSpec.Display

      @trialGenerator = @display.Trial


    buildStimulus: (event) ->
      stimType = _.keys(event)[0]
      params = _.values(event)[0]
      @stimFactory.makeStimulus(stimType, params)

    buildEvent: (event) ->
      responseType = _.keys(event)[0]
      params = _.values(event)[0]
      @stimFactory.makeResponse(responseType, params)

    buildTrial: (eventSpec, record) ->

      events = for key, value of eventSpec
        stimSpec = _.omit(value, "Next")
        responseSpec = _.pick(value, "Next")

        stim = @buildStimulus(stimSpec)
        response = @buildEvent(responseSpec.Next)
        @stimFactory.makeEvent(stim, response)

      new Trial(events, record)

    start: (context) ->
      #numBlocks = @design.blocks
      trials = @design.fullDesign
      console.log(trials.nrow())
      trialList = for i in [0 ... trials.nrow()]
        record = trials.record(i)
        record.$trialNumber = i
        trialSpec = @trialGenerator(record)
        @buildTrial(trialSpec, record)

      context.start(trialList)



# ## ConditionalSampler
exports.ConditionalSampler =
  class ConditionalSampler extends Sampler

    makeItemSubsets: () ->
      ctable = @factorSpec.conditionTable

      keySet = for i in [0...ctable.nrow()]
        record = ctable.record(i)
        levs = _.values(record)
        _.reduce(levs, ((a, b) ->
          a + ":" + b))

      console.log(keySet)


      itemSets = for i in [0...ctable.nrow()]
        record = ctable.record(i)
        indices = @itemMap.whichRow(record)
        @items[j] for j in indices

      console.log(itemSets)

      _.zipObject(keySet, itemSets)

    constructor: (@items, @itemMap, @factorSpec) ->
      @keyMap = @makeItemSubsets()
      @conditions = _.keys(@keyMap)
      @samplerSet = {}

      for key, value of @keyMap
        @samplerSet[key] = new ExhaustiveSampler(value)

    take: (n) ->
      keys = repLen(@conditions, n)
      _.flatten(@takeCondition(keys))

    takeCondition: (keys) ->
      (@samplerSet[key].take(1) for key in keys)


exports.VarSpec =
  class VarSpec
    @name = ""
    @nblocks = 1
    @reps = 1
    @expanded = {}

    ntrials: ->
      @nblocks * @reps

    valueAt: (block, trial) ->



exports.FactorSpec =
  class FactorSpec extends VarSpec

    constructor: (@nblocks, @reps, @name, @levels) ->
      console.log(@name)
      console.log(@levels)
      @factorSet = {}
      @factorSet[@name] = @levels
      @conditionTable = DataTable.expand(@factorSet)
      @expanded = @expand(@nblocks, @reps)

    cross: (other) ->
      new CrossedFactorSpec(@nblocks, @reps, [this, other])

    names: ->
      @name

    expand: (nblocks, reps) ->
      prop = {}
      prop[@name] = @levels
      vset = new DataTable(prop)

      blocks = for i in [1..nblocks]
        vset.replicate(reps)
      concatBlocks = _.reduce(blocks, (sum, nex) ->
        DataTable.rbind(sum, nex))
      concatBlocks.bindcol("BLOCK", rep([1..nblocks], rep(reps * vset.nrow(), nblocks)))
      concatBlocks

    valueAt: (block, trial) ->
      @expanded[block][@name][trial]


exports.CrossedFactorSpec =
  class CrossedFactorSpec extends VarSpec
    constructor: (@nblocks, @reps, @parents) ->
      @parentNames = (fac.name for fac in @parents)
      @name = _.reduce(@parentNames, (n, n1) ->
        n + ":" + n1)
      @levels = (fac.levels for fac in @parents)
      @factorSet = _.zipObject(@parentNames, @levels)
      @conditionTable = DataTable.expand(@factorSet)
      @expanded = @expand(@nblocks, @reps)

    names: ->
      @parentNames

    expand: (nblocks, reps) ->
      blocks = for i in [1..nblocks]
        @conditionTable.replicate(reps)
      concatBlocks = _.reduce(blocks, (sum, nex) ->
        DataTable.rbind(sum, nex))
      concatBlocks.bindcol("BLOCK", rep([1..nblocks], rep(reps * @conditionTable.nrow(), nblocks)))
      concatBlocks

    valueAt: (block, trial) ->
      @expanded[block][name][trial] for name in @parentNames


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
        _.reduce(levs, ((a, b) ->
          a + ":" + b))


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

      @varnames = _.keys(@variables)

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

      @fullDesign = @crossedSpec.expanded.bindcol(_.keys(crossedItems)[0],
        crossedSampler.take(@crossedSpec.expanded.nrow()))

      console.log(@crossedDesign)


dt1 = DataTable.fromRecords([{a:1, b:2}, {c:1, d:2, a:88}])
dt2 = DataTable.fromRecords([{a:1, b:2}])
dt2.show()

dt3 = DataTable.rbind(dt1, dt2, true)
dt3.show()
#dt = new DataTable({x: [1,2,3,4,5,2,1], y: ['a', 'b', 'b', 'c', 'd', 'e', 'a']})
#res = dt.select({y: 'b'})
#console.log(res)

#dt2 = dt.bindrow([{x: 26, y: 'u'}, {x:66, y:88}])
#dt2.show()


