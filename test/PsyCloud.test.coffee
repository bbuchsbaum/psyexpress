module("DataTable")
test 'can create a DataTable from a single record, and it has one row', ->
  record = {a:1, b: 2, c: 3}
  dt =new Psy.DataTable.fromRecords([record])
  equal(dt.nrow(), 1)

test 'can create a DataTable from a two records, and it has two rows', ->
  records = [{a:1, b: 2, c: 3},{a:1, b: 2, c: 3}]
  dt =new Psy.DataTable.fromRecords(records)
  equal(dt.nrow(), 2)

test 'can create a DataTable from a two records, with partially overlapping keys', ->
  records = [{a:1, b: 2, c: 3},{b: 2, c: 3, x:7}]
  dt = new Psy.DataTable.fromRecords(records)
  equal(dt.ncol(), 4)
  equal(dt.nrow(), 2)

test 'can concatenate two DataTables with different column names with rbind, union=true', ->
  dt1 = new Psy.DataTable({a: [1,2,3], b:[5,6,7]})
  dt2 = new Psy.DataTable({a: [1,2,3], d:[5,6,7]})

  dt3 = Psy.DataTable.rbind(dt1,dt2,true)
  equal(3, dt3.ncol())
  equal(6, dt3.nrow())


module("FactorNode")
test 'Can create a FactorNode from an object literal', ->
  fnode =
    fac:
      levels: [1,2,3,4,5]
  fac = new Psy.FactorNode.build("fac", fnode.fac)

  equal(fac.name, "fac")
  equal(fac.levels.toString(), [1,2,3,4,5].toString(), fac.levels)

module("FactorSetNode")
test 'can create a FactorSetNode from an object literal', ->
  fset =
    FactorSet:
      wordtype:
        levels: ["word", "pseudo"]
      repnum:
        levels: [1,2,3,4,5,6]
      lag:
        levels: [1,2,4,8,16,32]

  fnode = Psy.FactorSetNode.build(fset["FactorSet"])
  equal(fnode.factorNames.toString(), ["wordtype", "repnum", "lag"].toString(), fnode.factorNames.toString())
  equal(fnode.varmap["wordtype"].levels.toString(), ["word", "pseudo"].toString(), fnode.varmap["wordtype"].levels.toString())
  #equal(fnode.cellTable.table.nrow(), 2*6*6)


module("TaskNode")
test 'TaskNode correctly extracts names of its inputs', ->
  fspec1 = new Psy.FactorSpec(1,1, "a", [1,2,3])
  fspec2 = new Psy.FactorSpec(1,1, "b", [5,7,9,21])
  fspec3 = new Psy.FactorSpec(1,1, "dddd", [5,7,9,21])
  tspec = new Psy.TaskNode([fspec1, fspec2, fspec3], [])
  equal(["a", "b", "dddd"].toString(), tspec.factorNames.toString())
  equal(tspec.varmap["a"].levels.toString(), [1,2,3].toString())



module("TaskSchema")
test 'can build a TaskSchema from object literal', ->
  schema =
    main:
      wordtype:
        levels: ["word", "pseudo"]
      repnum:
        levels: [1,2,3,4,5,6]
      lag:
        levels: [1,2,4,8,16,32]
    aux:
      novel:
        levels: ["a", "b", "c"]
      color:
        levels: ["red", "green", "blue"]


  xs = Psy.TaskSchema.build(schema)
  equal(["main", "aux"].toString(), xs.trialTypes())
  #console.log("schema trial types:", xs.trialTypes())
  console.log("main schema factors", xs.factors("main"))
  console.log("aux schema factors", xs.factors("aux"))

module("TrialList")
test 'can build a TrialList', ->
  tlist = new TrialList(6)
  tlist.add(0,{wordtype: "word", lag: 1, repnum: 1})
  tlist.add(0,{wordtype: "pseudo", lag: 2, repnum: 2})
  tlist.add(0,{wordtype: "word", lag: 4, repnum: 3})
  tlist.add(1,{wordtype: "word", lag: 2, repnum: 3})
  tlist.add(18,{wordtype: "word", lag: 2, repnum: 3})

  console.log("TLIST", tlist.ntrials())
  console.log("TLIST", tlist.get(0,2))


module("ItemNode")
test 'can build an ItemNode from object literal', ->
  inode =
    items: ["a", "b", "c"]
    attributes:
      x: [1,2,3]
      y: [4,5,6]
    type: "text"

  node = Psy.ItemNode.build("inode", inode)
  equal(node.name, "inode")
  equal(node.attributes.x.toString(), [1,2,3].toString(), node.attributes.x.toString())
  equal(node.attributes.y.toString(), [4,5,6].toString(), node.attributes.x.toString())



module("AbsoluteLayout")

test 'AbsoluteLayout correcty converts percentage to fraction', ->
  layout = new Psy.AbsoluteLayout()
  xy = layout.computePosition([1000,1000], ["10%", "90%"])
  equal(xy[0], 1000 * 0.10, "10% of 1000 is " + xy[0])
  equal(xy[1], 1000 * 0.90, "90% of 1000 is " + xy[1])

test 'AbsoluteLayout handles raw pixels', ->
  layout = new Psy.AbsoluteLayout()


  xy = layout.computePosition([1000, 1000], [10, 90])
  equal(xy[0], 10)
  equal(xy[1], 90)



