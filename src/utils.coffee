_ = require('lodash')

#$ = window?.jQuery or window?.Zepto or (element) -> element


if window?.performance?.now
  getTimestamp = -> window.performance.now()
else if window?.performance?.webkitNow
  getTimestamp = -> window.performance.webkitNow()
else
  getTimestamp = -> new Date().getTime()

exports.getTimeStamp = getTimestamp

@browserBackDisabled = false

exports.disableBrowserBack = ->
  if not @browserBackDisabled
    rx = /INPUT|SELECT|TEXTAREA/i

    @browserBackDisabled = true

    $(document).bind("keydown keypress", (e) ->
      if e.which is 8
        if !rx.test(e.target.tagName) or e.target.disabled or e.target.readOnly
          e.preventDefault())


exports.module = (name) ->
  global[name] = global[name] or {}

exports.asArray = (value) ->
  if (_.isArray(value))
    value
  else if (_.isNumber(value) or _.isBoolean(value))
    [value]
  else
    _.toArray(value)

exports.permute = (input) ->
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


exports.rep = (vec, times) ->
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

exports.repLen = (vec, length) ->
  if (length < 1)
    throw "repLen: length must be greater than or equal to 1"

  for i in [0...length]
    vec[i % vec.length]


exports.sample = (elements, n, replace=false) ->
  if n > elements.length and not replace
    throw "cannot take sample larger than the number of elements when 'replace' argument is false"
  if not replace
    _.shuffle(elements)[0...n]
  else
    for i in [0...n]
      Math.floor(Math.random() * elements.length)


exports.doTimer = (length, oncomplete) ->
  start = getTimestamp()
  instance = ->
    diff = (getTimestamp() - start)
    if diff >= length
      oncomplete(diff)
    else
      half = Math.max((length - diff)/2,1)
      if half < 20
        half = 1
      setTimeout instance, half

  setTimeout instance, 1