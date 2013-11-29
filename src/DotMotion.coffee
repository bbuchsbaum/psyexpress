
Psy = require("./PsyCloud")
El = require("./Elements")
_ = require('lodash')



class DotSet

  @randomDelta: (distance) ->
    rads = Math.random() * Math.PI * 2
    [distance * Math.cos(rads), distance * Math.sin(rads)]

  @coherentDelta: (distance, direction) ->
    [distance * Math.cos(Math.PI * direction/180), distance * Math.sin(Math.PI * direction/180)]

  @pointInCircle: ->
    t = 2*Math.PI*Math.random()
    u = Math.random()+Math.random()
    r = if u>1 then 2-u else u
    [r*Math.cos(t), r*Math.sin(t)]


  @inCircle: (center_x, center_y, radius, x, y) ->
    squareDist = Math.pow((center_x - x), 2) + Math.pow(center_y - y, 2)
    squareDist <= Math.pow(radius, 2)


  constructor: (@ndots, @nparts=3, coherence=.5) ->
    @frameNum = 0
    @dotsPerSet = Math.round(@ndots/@nparts)
    @dotSets = _.map([0...3], (i) =>
      _.map([0...@dotsPerSet], (d) ->
        [Math.random(), Math.random()]
        ##DotSet.pointInCircle())
      )
    )

  getDotPartition: (i) -> @dotSets[i]

  nextFrame: (coherence, distance, direction) ->
    partition = @frameNum % @nparts
    dset = @dotSets[partition]
    res = for i in [0...dset.length]
      xy = dset[i]
      delta =
        if Math.random() < coherence
          DotSet.coherentDelta(distance, direction)
        else
          DotSet.randomDelta(distance)

      xy = [xy[0] + delta[0], xy[1] + delta[1]]
      #if not DotSet.inCircle(.5,.5,.5, xy[0], xy[1])
      #  xy = DotSet.pointInCircle()
      if (xy[0] < 0 or xy[0] > 1 or xy[1] < 0 or xy[1] > 1)
        xy = [Math.random(), Math.random()]
      dset[i] = xy

    @frameNum = @frameNum + 1
    res


exports.RandomDotMotion =
class RandomDotMotion extends El.Stimulus
  constructor: (spec={x: 0, y: 0, numDots: 70, apRadius:400, dotSpeed: .02, dotSize:2, coherence: .55, partitions: 3}) ->
    @numDots = spec.numDots
    @apRadius = spec.apRadius
    @dotSpeed = spec.dotSpeed
    @dotSize = spec.dotSize
    @coherence = spec.coherence
    @partitions = spec.partitions
    @x = spec.x
    @y = spec.y


    @dotSet = new DotSet(@numDots, 3, .5)

  createDots: () ->
    dots = @dotSet.nextFrame(@coherence, @dotSpeed, 180)
    for xy in dots
      new Kinetic.Rect({ x: @x + @apRadius*xy[0], y: @x + @apRadius*xy[1], width: @dotSize, height: @dotSize, fill: "green"})

  createInitialDots: () ->
    for i in [0...@partitions]
      dpart = @dotSet.getDotPartition(i)
      for xy in dpart
        new Kinetic.Rect({ x: @x + @apRadius*xy[0], y: @x + @apRadius*xy[1], width: @dotSize, height: @dotSize, fill: "green"})

  displayInitialDots: (nodes, group) ->
    for node in nodes
      group.add(node)
    #layer.drawScene()

  render: (context, layer) ->
    @groups = for i in [0...@partitions]
      new Kinetic.Group({listening: false})

    _.map(@groups, (g) -> layer.add(g))

    nodeSets = @createInitialDots()

    for i in [0...@partitions]
      @displayInitialDots(nodeSets[i], @groups[i])

    layer.draw()


    @anim = new Kinetic.Animation((frame) =>

      dx = @dotSet.nextFrame(@coherence, @dotSpeed, 180)
      part = @dotSet.frameNum % @partitions

      curset = nodeSets[part]

      for i in [0...curset.length]
        xy = dx[i]
        xy = [xy[0] * @apRadius, xy[1] * @apRadius]
        console.log(xy)
        curset[i].setPosition(xy)
        if not DotSet.inCircle(.5*@apRadius, .5*@apRadius, @apRadius/2, xy[0], xy[1])
          curset[i].hide()
        else
          curset[i].show()

        #@groups[part].clear()

    , layer)

    layer.draw()
    @anim.start()


  render2: (context, layer) ->

    @layers = for i in [0...@partitions]
      new Kinetic.Layer({listening: false})

    _.map(@layers, (l) -> context.stage.add(l))

    nodeSets = @createInitialDots()
    for i in [0...@partitions]
      @displayInitialDots(nodeSets[i], @layers[i])

    @anim = new Kinetic.Animation((frame) =>
      dx = @dotSet.nextFrame(@coherence, @dotSpeed, 180)
      part = @dotSet.frameNum % @partitions

      curset = nodeSets[part]


      for i in [0...curset.length]
        xy = dx[i]
        xy = [xy[0] * @apRadius, xy[1] * @apRadius]
        console.log(xy)
        curset[i].setPosition(xy)

      @layers[part].draw()
    )

    layer.draw()
    @anim.start()

  stop: (context) ->
    @anim.stop()
    #for layer in @layers
    #  context.stage.remove(layer)











x = new DotSet(51,3)
console.log(x.dotSets)

console.log("NEXT", x.nextFrame(.5, .01, 180))