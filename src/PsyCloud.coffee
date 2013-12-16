_ = require('lodash')
Q = require("q")
TAFFY = require("taffydb").taffy
utils = require("./utils")
DataTable = require("./datatable").DataTable



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


exports.RunnableNode =
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
        console.log("caught error", err)
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
      console.log("starting event", @stimulus.name)
      super(context)


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
        context.updateState( =>
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
          console.log("last event ", context.eventDB().last())
          spec = @feedback(context.eventDB)
          console.log("spec is", spec)
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

        if @blockSpec? and @blockSpec.End
          spec = @blockSpec.End(context)
          @showEvent(spec, context)
        else
          Q.fcall(0)


    #after: (context) ->

exports.BlockSeq =
  class BlockSeq extends RunnableNode
    constructor: (children) -> super(children)

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
      ret = $.extend({}, this)
      ret.inPrelude = true
      ret

    outsidePrelude: ->
      ret = $.extend({}, this)
      ret.inPrelude = false
      ret

    nextBlock: (block) ->
      ret = $.extend({}, this)
      ret.blockNumber = @blockNumber + 1
      ret.block = block
      ret

    nextTrial: (trial) ->
      ret = $.extend({}, this)
      ret.trial = trial
      ret.trialNumber = @trialNumber + 1
      ret

    nextEvent: (event) ->
      console.log("next Event")
      ret = $.extend({}, this)
      ret.event = event
      ret.eventNumber = @eventNumber + 1
      ret

    toRecord: ->
      ret = {
        $blockNumber: @blockNumber
        $trialNumber: @trialNumber
        $eventNumber: @eventNumber
        $stimulus: @event?.stimulus?.constructor?.name
        $response: @event?.response?.constructor?.name
        $stimulusID: @event?.stimulus?.id
        $responseID: @event?.response?.id

      }

      if not _.isEmpty(@trial) and @trial.record?
        for key, value of @trial.record
          ret[key] = value
      ret




exports.ExperimentContext =
  class ExperimentContext
    constructor: (@stimFactory) ->
      @eventDB = TAFFY({})

      @exState = new ExperimentState()

      @eventData = new EventDataLog()

      @log = []

      @trialNumber = 0

      @currentTrial =  new Trial([], {})

    updateState: (fun) ->
      @exState = fun(@exState)
      console.log("new state is", @exState)
      console.log("record is", @exState.toRecord())
      @exState

    pushData: (data, withState=true) ->
      if withState
        record = _.extend(@exState.toRecord(), data)
      else
        record = data

      @eventDB.insert(record)
      console.log("db is now", @eventDB().get())


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

    insertHTMLDiv: ->
      $("canvas").css("position", "absolute")
      #$(".kineticjs-content").css("position", "absolute")


      $("#container" ).append("""
        <div id="htmlcontainer" class="htmllayer"></div>
      """)

      $("#htmlcontainer").css(
        position: "absolute"
        "z-index": 999
        outline: "none"
        padding: "5px"
      )

      $("#container").attr("tabindex", 0)
      $("#container").css("outline", "none")
      $("#container").css("padding", "5px")


    clearHtml: ->
      $("#htmlcontainer").empty()
      $("#htmlcontainer").hide()

    appendHtml: (input) ->
      $("#htmlcontainer").addClass("htmllayer")
      $("#htmlcontainer").append(input)
      $("#htmlcontainer").show()

    hideHtml: ->
      $("#htmlcontainer").hide()
      #$("#htmlcontainer").empty()



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

  console.log("building trial with record", record)

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
        #record.$trialNumber = trialNum
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







    #valueAt: (block, trial) ->
    #  @expanded[block][@name][trial]







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



exports.buildStimulus = buildStimulus
exports.buildResponse = buildResponse
exports.buildEvent = buildEvent
exports.buildTrial = buildTrial
exports.buildPrelude = buildPrelude




