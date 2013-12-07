_ = require('lodash')
Q = require("q")


clone = (obj) ->
  if not obj? or typeof obj isnt 'object'
    return obj

  if obj instanceof Date
    return new Date(obj.getTime())

  if obj instanceof RegExp
    flags = ''
    flags += 'g' if obj.global?
    flags += 'i' if obj.ignoreCase?
    flags += 'm' if obj.multiline?
    flags += 'y' if obj.sticky?
    return new RegExp(obj.source, flags)

  newInstance = new obj.constructor()

  for key of obj
    newInstance[key] = clone obj[key]

  return newInstance


asArray = (value) ->
  if (_.isArray(value))
    value
  else if (_.isNumber(value) or _.isBoolean(value))
    [value]
  else
    _.toArray(value)

#seqalong = (vec) -> [0 .. vec.length - 1]

permute = (input) ->
  permArr = []
  usedChars = []

  exports.main = main = (input) ->

    for i in [0...input.length]
      ch = input.splice(i, 1)[0]
      usedChars.push(ch)
      if (input.length == 0)
        permArr.push(usedChars.slice())

      main(input)
      input.splice(i, 0, ch)
      usedChars.pop()

    permArr

  main(input)


rep = (vec, times) ->
  if not (times instanceof Array)
    times = [times]

  if (times.length != 1 and vec.length != times.length)
    throw "vec.length must equal times.length or times.length must be 1"
  if vec.length == times.length
    out = for el, i in vec
      for j in [1..times[i]]
        el
    _.flatten(out)
  else
    out = _.times(times[0], (n) => vec)
    _.flatten(out)

repLen = (vec, length) ->
  if (length < 1)
    throw "repLen: length must be greater than or equal to 1"

  for i in [0...length]
    vec[i % vec.length]


sample = (elements, n, replace=false) ->
  if n > elements.length and not replace
    throw "cannot take sample larger than the number of elements when 'replace' argument is false"
  if not replace
    _.shuffle(elements)[0...n]
  else
    for i in [0...n]
      Math.floor(Math.random() * elements.length)



exports.EventData =
class EventData
  constructor: (@name, @id, @data) ->

exports.EventDataLog =
class EventDataLog
  constructor: ->
    @eventStack = []

  push: (ev) ->
    @eventStack.push(ev)

  last: ->
    if @eventStack.length < 1
      throw "EventLog is Empty, canot access last element"
    @eventStack[@eventStack.length-1].data

  findAll: (id) ->
    _.filter(@eventStack, (ev) -> ev.id == id)


  findLast: (id) ->
    len = @eventStack.length - 1
    for i in [len .. 0]
      return @eventStack[i] if @eventStack[i].id is id


# ## Sampler
# basic sampler that does not recycle its elements or allow sampling with replacement
exports.Sampler =
  class Sampler

    constructor: (@items) ->

    sampleFrom: (items, n) ->
      sample(items, n)

    take: (n) ->
      if n > @items.length
        throw "cannot take sample larger than the number of items when using non-replacing sampler"
      @sampleFrom(@items, n)

    #takeWithout: (n, exclusionSet) ->
    #  pool = _.difference(@items, exclusionSet)
    #  res = []
    #  while (res.length != n)
    #    sam = @take(1)
    #    res.push(_.difference(sam, exclusionSet))
    #    res = _.flatten(res)
    #  _.flatten(res)



# ## ExhaustiveSampler
exports.ExhaustiveSampler =
  class ExhaustiveSampler extends Sampler

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



exports.MatchSampler =
class MatchSampler
  constructor: (@sampler) ->

  take: (n, match=true) ->
    sam = @sampler.take(n)
    if match
      probe = sample(sam, 1)[0]
    else
      probe = @sampler.take(1)[0]

    probeIndex = _.indexOf(sam, probe)

    {targetSet: sam, probe: probe, probeIndex: probeIndex, match: match}

msam = new MatchSampler(new ExhaustiveSampler([0..25]))
console.log("match:", msam.take(5))
console.log("non match:", msam.take(5, false))



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

exports.CombinatoricSampler =
class CombinatoricSampler extends Sampler

  constructor: (@samplers...) ->

  take: (n) ->
    for i in [0...n]
      xs = for j in [0...@samplers.length]
        @samplers[j].take(1)
      _.flatten(xs)

exports.GridSampler =
class GridSampler extends Sampler
  constructor: (@x, @y) ->
    @grid = DataTable.expand({x:@x, y:@y})
    console.log("rows:", @grid.nrow())
    @tuples = for i in [0...@grid.nrow()]
      _.values(@grid.record(i))

  take: (n) ->
    sample(@tuples, n)



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
      d = _.map(vars, (x) -> x.length)

      orep = _.reduce(d, (x, acc) -> x * acc)
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
          if (not _.has(this, key))
            throw new Error("DataTable has no field named #{key}")
          else
            this[key].push(value)
      this


exports.StimFactory =
  class StimFactory

    buildStimulus: (spec, context) ->

      stimType = _.keys(spec)[0]
      params = _.values(spec)[0]


      @makeStimulus(stimType, params, context)

    buildResponse: (spec, context) ->
      responseType = _.keys(spec)[0]
      params = _.values(spec)[0]

      @makeResponse(responseType, params, context)

    buildEvent: (spec, context) ->
      stimSpec = _.omit(spec, "Next")
      responseSpec = _.pick(spec, "Next")

      stim = @buildStimulus(stimSpec, context)
      response = @buildResponse(responseSpec.Next, context)
      @makeEvent(stim, response, context)

    makeStimulus: (name, params,context) -> throw "unimplemented"

    makeResponse: (name, params, context) -> throw "unimplemented"

    makeEvent: (stim, response, context) -> throw "unimplemented"


exports.MockStimFactory =
  class MockStimFactory extends StimFactory
    makeStimulus: (name, params, context) ->
      ret = {}
      ret[name] = params
      ret

    makeResponse: (name, params, context) ->
      ret = {}
      ret[name] = params
      ret

    makeEvent: (stim, response, context) ->
      [stim, response]



class RunnableNode

  constructor: (@children) ->

  @functionList: (nodes, context, callback) ->
    ## for every runnable node, create a function that returns a promise via 'node.start'
    _.map(nodes, (node) => (=>
      callback(node) if callback?
      node.start(context)
    ))


  before: (context) ->
    -> 0


  after: (context) ->
    -> 0


  @chainFunctions: (funArray) ->
    ## start with a dummy promise
    result = Q.resolve(0)

    ## sequentially chain the promise-producing functions in an array 'funArray'
    ## 'result' is the promise chain.
    for fun in funArray
      result = result.then(fun,
      (err) ->
        throw new Error("Error during execution: ", err)
      )
    result

  numChildren: -> @children.length

  length: -> @children.length

  start: (context) ->
    farray = RunnableNode.functionList(@children, context,
    (node) ->
      console.log("callback", node)
    )

    RunnableNode.chainFunctions(_.flatten([@before(context), farray, @after(context)]))


  stop: (context) ->

exports.RunnableNode = RunnableNode


exports.Event =
  class Event extends RunnableNode

    constructor: (@stimulus, @response) ->
      super([@response])

    stop: (context) ->
      @stimulus.stop(context)
      @response.stop(context)


    before: (context) ->
      =>
        self = this

        if not context.exState.inPrelude
          console.log("event not in prelude")
          context.updateState( =>
            context.exState.nextEvent(self)
          )

        if not @stimulus.overlay
          context.clearContent()

        @stimulus.render(context, context.contentLayer)
        context.draw()

    after: (context) ->
      =>
        @stimulus.stop(context)


    start: (context) ->
      super(context)
      ## activate response
      #@response.activate(context).then((ret) =>
      #  ##
      #  @stimulus.stop(context)
      #  ret
      #,
      #  (err) ->
      #    throw new Error("Error during Response activation", err)
      #)


exports.Trial =
  class Trial extends RunnableNode
    constructor: (events = [], @record={}, @feedback, @background) ->
      super(events)

    numEvents: ->
      @children.length

    push: (event) -> @children.push(event)

    before: (context) ->
      =>
        self = this
        console.log("before trial")
        context.updateState( =>
          console.log("updating trial state")
          context.exState.nextTrial(self)
        )

        context.clearBackground()

        if @background?
          context.setBackground(@background)
          context.drawBackground()


    after: (context) ->
      ## return a function that executes feedback operation
      =>
        if @feedback?
          spec = @feedback(context.eventData)
          event = context.stimFactory.buildEvent(spec, context)
          event.start(context)
        else
          Q.fcall(0)


    start: (context) ->

      farray = RunnableNode.functionList(@children, context,
        (event) ->
          console.log("event callback", event)
      )

      RunnableNode.chainFunctions(_.flatten([@before(context), farray, @after(context)]))


    stop: (context) -> #ev.stop(context) for ev in @events


exports.Block =
  class Block extends RunnableNode
    constructor: (children, @blockSpec) ->
      super(children)


    showEvent: (spec, context) ->
      event = buildEvent(spec, context)
      event.start(context)

    before: (context) ->
      self = this
      =>
        console.log("updating block state")
        context.updateState( =>
          context.exState.nextBlock(self)
        )

        if @blockSpec? and @blockSpec.Start
          spec = @blockSpec.Start(context)
          @showEvent(spec, context)
        else
          Q.fcall(0)



    after: (context) ->
      =>
        console.log("after Block function")
        if @blockSpec? and @blockSpec.End
          spec = @blockSpec.End(context)
          @showEvent(spec, context)
        else
          Q.fcall(0)


    #after: (context) ->


exports.Prelude =
  class Prelude extends RunnableNode
    constructor: (children) -> super(children)

    before: (context) ->
      =>
        context.updateState( =>
          console.log("setting in prelude!")
          console.log("exState is", context.exState)
          context.exState.insidePrelude()
        )

    after: (context) ->
      =>
        context.updateState( =>
          context.exState.outsidePrelude()
        )



exports.BlockSeq =
  class BlockSeq extends RunnableNode
    constructor: (children) -> super(children)




exports.ExperimentState =
  class ExperimentState

    constructor: () ->
      @inPrelude = false
      @trial = {}
      @block = {}
      @event = {}
      @blockNumber = 0
      @trialNumber = 0
      @eventNumber = 0

      @stimulus = {}
      @response = {}


    insidePrelude: ->
      console.log("in prelude")
      ret = clone(this)
      console.log("cloned state", ret)
      ret.inPrelude = true
      ret

    outsidePrelude: ->
      console.log("out prelude")
      ret = clone(this)
      console.log("cloned state", ret)
      ret.inPrelude = false
      ret

    nextBlock: (block) ->
      console.log("next Block")
      #ret = clone(this)
      ret = _.clone(this)
      console.log("cloned state", ret)
      ret.blockNumber = @blockNumber + 1
      ret.block = block
      ret

    nextTrial: (trial) ->
      console.log("next Trial", trial)
      console.log("trying to clone")
      #ret = clone(this)
      ret = _.clone(this)
      console.log("clone success!")
      ret.trial = trial
      ret.trialNumber = @trialNumber + 1
      console.log("ret trial is", ret)
      ret

    nextEvent: (event) ->
      console.log("next Event")
      #ret = clone(this)
      ret = _.clone(this)
      ret.event = event
      ret.eventNumber = @eventNumber + 1
      ret

    toRecord: ->
      {
        $blockNumber: @blockNumber
        $trialNumber: @trialNumber
        $eventNumber: @eventNumber
        $stimulus: @event?.stimulus?.constructor.name
        $response: @event?.response?.constructor.name
        #$stimulusID: @event?.stimulus?.id
        #$responseID: @event?.response?.id

      }

      if @trial?.record?
        for key, value in @trial.record
          ret[key] = value
      ret





#x1 = new ExperimentState()
#x2 = x1.nextBlock()
#console.log("ESTATE", x2)




exports.ExperimentContext =
  class ExperimentContext
    constructor: (@stimFactory) ->
      @exState = new ExperimentState()

      @eventData = new EventDataLog()

      @log = []

      @trialNumber = 0

      @currentTrial =  new Trial([], {})

    updateState: (fun) ->
      @exState = fun(@exState)
      console.log("new state is", @exState)
      #console.log("record is", @exState.toRecord())
      @exState

    pushEventData: (ev) ->
      @eventData.push(ev)

    logEvent: (key, value) ->

      record = _.clone(@currentTrial.record)
      record[key] = value
      @log.push(record)
      console.log(@log)


    showEvent: (event) ->
      event.start(this)

    start: (blockList) ->
      try
        farray = RunnableNode.functionList(blockList, this,
          (block) ->
            console.log("block callback", block)
        )

        #@trialNumber += 1
        #@currentTrial = trial
        #trial.start(this)

        RunnableNode.chainFunctions(farray)

      catch error
        console.log("caught error:", error)

      #result.done()


    clearContent: ->

    clearBackground: ->

    keydownStream: -> #Bacon.fromEventTarget(window, "keydown")

    keypressStream: -> #Bacon.fromEventTarget(window, "keypress")

    mousepressStream: ->

    draw: ->


buildStimulus = (spec, context) ->
  stimType = _.keys(spec)[0]
  params = _.values(spec)[0]
  context.stimFactory.makeStimulus(stimType, params, context)

buildResponse =  (spec, context) ->
  responseType = _.keys(spec)[0]
  console.log("response type", responseType)
  params = _.values(spec)[0]
  console.log("params", params)
  context.stimFactory.makeResponse(responseType, params, context)

buildEvent = (spec, context) ->
  stimSpec = _.omit(spec, "Next")
  responseSpec = _.pick(spec, "Next")

  console.log("stim Spec", stimSpec)
  console.log("response Spec",responseSpec)

  if not responseSpec? or _.isEmpty(responseSpec)
    console.log("keys of stimspec", _.keys(stimSpec))
    ## in the absence of a 'Next' element, assume stimulus is it's own response
    stim = buildStimulus(stimSpec, context)
    console.log("stim is", stim)
    context.stimFactory.makeEvent(stim, stim, context)
  else
    stim = buildStimulus(stimSpec, context)
    console.log("stim", stim)
    response = buildResponse(responseSpec.Next, context)
    console.log("response", response)
    context.stimFactory.makeEvent(stim, response, context)


buildTrial = (eventSpec, record, context, feedback, background) ->
  events = for key, value of eventSpec
    stimSpec = _.omit(value, "Next")
    responseSpec = _.pick(value, "Next")

    stim = buildStimulus(stimSpec, context)
    response = buildResponse(responseSpec.Next, context)
    context.stimFactory.makeEvent(stim, response, context)

  new Trial(events, record, feedback, background)


buildPrelude = (preludeSpec, context) ->
  console.log("building prelude")
  events = for key, value of preludeSpec
    spec = {}
    spec[key] = value
    console.log("prelude spec", spec)
    buildEvent(spec, context)
  console.log("prelude events", events)
  new Prelude(events)




exports.Presenter =
class Presenter
  constructor: (@trialList, @display, @context) ->
    @trialBuilder = @display.Trial

    @prelude = if @display.Prelude?
      buildPrelude(@display.Prelude, @context)
    else
      new Prelude([])



    console.log("prelude is", @prelude)

  start: () ->

    @blockList = new BlockSeq(for block in @trialList.blocks
      trials = for trialNum in [0...block.length]
        record = _.clone(block[trialNum])
        record.$trialNumber = trialNum
        trialSpec = @trialBuilder(record)
        buildTrial(trialSpec.Events, record, @context, trialSpec.Feedback)
      new Block(trials, @display.Block)
    )

    @prelude.start(@context).then(=> @blockList.start(@context))


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


    buildStimulus: (event, context) ->
      stimType = _.keys(event)[0]
      params = _.values(event)[0]
      @stimFactory.makeStimulus(stimType, params, context)

    buildEvent: (event, context) ->
      responseType = _.keys(event)[0]
      params = _.values(event)[0]
      @stimFactory.makeResponse(responseType, params, context)

    buildTrial: (eventSpec, record, context) ->

      events = for key, value of eventSpec
        stimSpec = _.omit(value, "Next")
        responseSpec = _.pick(value, "Next")

        stim = @buildStimulus(stimSpec)
        response = @buildResponse(responseSpec.Next)
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
        @buildTrial(trialSpec, record, context)

      context.start(trialList)



# ## ConditionalSampler
exports.ConditionalSampler =
  class ConditionalSampler extends Sampler

    makeItemSubsets: () ->
      ctable = @factorSpec.conditionTable

      keySet = for i in [0...ctable.nrow()]
        record = ctable.record(i)
        levs = _.values(record)
        _.reduce(levs, ((a, b) -> a + ":" + b))

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
      concatBlocks.bindcol("$Block", rep([1..nblocks], rep(reps * vset.nrow(), nblocks)))
      concatBlocks

    #valueAt: (block, trial) ->
    #  @expanded[block][@name][trial]


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
      #concatBlocks = _.reduce(blocks, (sum, nex) -> DataTable.rbind(sum, nex))
      #concatBlocks.bindcol("$Block", rep([1..nblocks], rep(reps * @conditionTable.nrow(), nblocks)))
      #concatBlocks

    #valueAt: (block, trial) ->
    #  @expanded[block][name][trial] for name in @parentNames






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

exports.Iterator =
class Iterator

  hasNext: -> false
  next: -> throw "empty iterator"
  map: (f) ->

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

sam = new GridSampler([1,2,3], [1,2,3])
console.log("grid", sam.take(5))


des = Design:
  Blocks: [
      [
        a:1, b:2, c:3
        a:2, b:3, c:4
      ],
      [
        a:5, b:7, c:6
        a:5, b:7, c:6
      ]

  ]

console.log(des.Blocks)


prom = Q.fcall ->
  console.log("promise 1")
  1

prom2 = prom.then( (input) ->
  console.log("input is", input)
  input + 1
)

prom3 = prom2.then( (input) ->
  console.log("input is", input)
  input + 1
).done()


deferred = Q.defer()
prom = deferred.promise
prom.then((x) -> console.log("resolved with", x))

deferred.resolve(44)




exports.permute = permute
exports.rep = rep
exports.repLen = repLen
exports.clone = clone
exports.sample = sample
exports.buildStimulus = buildStimulus
exports.buildResponse = buildResponse
exports.buildEvent = buildEvent
exports.buildTrial = buildTrial
exports.buildPrelude = buildPrelude




