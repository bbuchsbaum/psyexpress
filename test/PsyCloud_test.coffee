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


module("TaskSpec")
test 'TaskSpec correctly extracts names of its inputs', ->
  fspec1 = new Psy.FactorSpec(1,1, "a", [1,2,3])
  fspec2 = new Psy.FactorSpec(1,1, "b", [5,7,9,21])
  fspec3 = new Psy.FactorSpec(1,1, "dddd", [5,7,9,21])
  tspec = new Psy.TaskSpec([fspec1, fspec2, fspec3], [])
  equal(["a", "b", "dddd"].toString(), tspec.varnames.toString())
  equal(tspec.varmap["a"].levels.toString(), [1,2,3].toString())


