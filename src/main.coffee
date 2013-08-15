Exp = require("./Experiment")
Psy = require("./Psytools")

for key, value of Psy
  exports[key] = value

for key, value of Exp
  exports[key] = value



#_ = require("lodash")

#test = (spec = {}) ->
#  args = _.defaults(spec, {a:1, b:2, c:3 })
#  console.log(args)

#test
#  a:4
#  b:6
#  c:8

#x =
#  y: (t) -> "hello"

#sam = new Psy.ExhaustiveSampler([1,2,3,4])
#console.log(sam.take(3), sam.take(6), sam.take(3))