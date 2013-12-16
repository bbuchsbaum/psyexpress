
isPercentage = (perc) -> _.isString(perc) and perc.slice(-1) is "%"

convertPercentageToFraction = (perc, dim) ->
  frac = parseFloat(perc)/100
  frac = Math.min(1,frac)
  frac = Math.max(0,frac)
  frac * dim

convertToCoordinate = (val, d) ->
  if isPercentage val
    val = convertPercentageToFraction(val, d)
  else
    Math.min(val, d)

computeGridCells = (rows, cols, bounds) ->
  for row in [0...rows]
    for col in [0...cols]
      {
      x: bounds.x + bounds.width/cols * col
      y: bounds.y + bounds.height/rows * row
      width:  bounds.width/cols
      height: bounds.height/rows
      }


positionToCoord = (pos, offx, offy, width, height, xy) ->
  switch pos
    when "center" then [offx + width * .5, offy + height * .5]
    when "center-left" or "left-center" then [offx + width * 1/6, offy + height * .5]
    when "center-right" or "right-center" then [offx + width * 5/6, offy + height * .5]
    when "top-left" or "left-top" then [offx + width * 1/6, offy + height * 1/6]
    when "top-right" or "right-top" then [offx + width * 5/6, offy + height * 1/6]
    when "top-center" or "center-top" then [offx + width * .5, offy + height * 1/6]
    when "bottom-left" or "left-bottom" then [offx + width * 1/6, offy + height * 5/6]
    when "bottom-right" or "right-bottom" then [offx + width * 5/6, offy + height * 5/6]
    when "bottom-center" or "center-bottom" then [offx + width * .5, offy + height * 5/6]
    else xy

exports.Layout =
  class Layout

    constructor: ->

    computePosition: (dim, stim, constraints) -> throw new Error("unimplimented")



exports.AbsoluteLayout =
  class AbsoluteLayout extends Layout

    computePosition: (dim, constraints) ->
      x = convertToCoordinate(constraints[0], dim[0])
      y = convertToCoordinate(constraints[1], dim[1])
      [x,y]


#exports.DefaultLayout =
#class DefaultLayout extends exports.Layout



exports.GridLayout =
  class GridLayout extends Layout
    constructor: (@rows, @cols, @bounds) ->
      @ncells = @rows*@cols
      @cells = @computeCells()

    computeCells: -> computeGridCells(@rows, @cols, @bounds)

    #cellPosition: (dim, constraints) ->

    computePosition: (dim, constraints) ->
      if dim[0] != @bounds.width and dim[1] != @bounds.height
        @bounds.width = dim[0]
        @bounds.height = dim[1]
        @cells = @computeCells()

      cell = @cells[constraints[0]][constraints[1]]

      [cell.x + cell.width/2, cell.y + cell.height/2]

exports.positionToCoord = positionToCoord