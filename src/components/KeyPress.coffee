Q = require("q")
Response = require("../stimresp").Response
utils = require("../utils")


keyTable =
    8: 'backspace'
    9: 'tab'
    13: 'enter'
    16: 'shift'
    17: 'ctrl'
    18: 'alt'
    20: 'capslock'
    27: 'esc'
    32: 'space'
    33: 'pageup'
    34: 'pagedown'
    35: 'end'
    36: 'home'
    37: 'left'
    38: 'up'
    39: 'right'
    40: 'down'
    45: 'ins'
    46: 'del'
    91: 'meta'
    93: 'meta'
    224: 'meta'
    106: '*'
    107: '+'
    109: '-'
    110: '.'
    111 : '/'
    186: ';'
    187: '='
    188: ','
    189: '-'
    190: '.'
    191: '/'
    192: '`'
    219: '['
    220: "\\"
    221: ']'


for i in [1...20]
  keyTable[111 + i] = 'f' + i

for i in [1..9]
  keyTable[i + 96]


class KeyPress extends Response

  defaults:
    keys: ['1', '2'], correct: ['1']

  activate: (context) ->
    @startTime = utils.getTimestamp()
    myname = @name
    deferred = Q.defer()
    keyStream = context.keypressStream()
    keyStream.filter((event) =>
      char = String.fromCharCode(event.keyCode)
      _.contains(@spec.keys, char)).take(1).onValue((filtered) =>
      Acc = _.contains(@spec.correct, String.fromCharCode(filtered.keyCode))
      timestamp = utils.getTimestamp()

      resp =
        name: myname
        id: @id
        KeyTime: timestamp
        RT: timestamp - @startTime
        Accuracy: Acc
        KeyChar: String.fromCharCode(filtered.keyCode)

      context.pushData(resp)

      deferred.resolve(resp))

    deferred.promise


exports.KeyPress = KeyPress


class SpaceKey extends Response

  activate: (context) ->
    deferred = Q.defer()
    keyStream = context.keypressStream()
    keyStream.filter((event) =>
      event.keyCode == 32).take(1).onValue((event) =>
      deferred.resolve(event))

    deferred.promise


exports.SpaceKey = SpaceKey