// Generated by CoffeeScript 1.6.3
(function() {
  module("DataTable");

  test('can create a DataTable from a single record, and it has one row', function() {
    var dt, record;
    record = {
      a: 1,
      b: 2,
      c: 3
    };
    dt = new Psy.DataTable.fromRecords([record]);
    return equal(dt.nrow(), 1);
  });

  test('can create a DataTable from a two records, and it has two rows', function() {
    var dt, records;
    records = [
      {
        a: 1,
        b: 2,
        c: 3
      }, {
        a: 1,
        b: 2,
        c: 3
      }
    ];
    dt = new Psy.DataTable.fromRecords(records);
    return equal(dt.nrow(), 2);
  });

  test('can create a DataTable from a two records, with partially overlapping keys', function() {
    var dt, records;
    records = [
      {
        a: 1,
        b: 2,
        c: 3
      }, {
        b: 2,
        c: 3,
        x: 7
      }
    ];
    dt = new Psy.DataTable.fromRecords(records);
    equal(dt.ncol(), 4);
    return equal(dt.nrow(), 2);
  });

  test('can concatenate two DataTables with different column names with rbind, union=true', function() {
    var dt1, dt2, dt3;
    dt1 = new Psy.DataTable({
      a: [1, 2, 3],
      b: [5, 6, 7]
    });
    dt2 = new Psy.DataTable({
      a: [1, 2, 3],
      d: [5, 6, 7]
    });
    dt3 = Psy.DataTable.rbind(dt1, dt2, true);
    equal(3, dt3.ncol());
    return equal(6, dt3.nrow());
  });

  module("FactorNode");

  test('Can create a FactorNode from an object literal', function() {
    var fac, fnode;
    fnode = {
      fac: {
        levels: [1, 2, 3, 4, 5]
      }
    };
    fac = new Psy.FactorNode.build("fac", fnode.fac);
    equal(fac.name, "fac");
    return equal(fac.levels.toString(), [1, 2, 3, 4, 5].toString(), fac.levels);
  });

  module("FactorSetNode");

  test('can create a FactorSetNode from an object literal', function() {
    var fnode, fset;
    fset = {
      FactorSet: {
        wordtype: {
          levels: ["word", "pseudo"]
        },
        repnum: {
          levels: [1, 2, 3, 4, 5, 6]
        },
        lag: {
          levels: [1, 2, 4, 8, 16, 32]
        }
      }
    };
    fnode = Psy.FactorSetNode.build(fset["FactorSet"]);
    equal(fnode.factorNames.toString(), ["wordtype", "repnum", "lag"].toString(), fnode.factorNames.toString());
    return equal(fnode.varmap["wordtype"].levels.toString(), ["word", "pseudo"].toString(), fnode.varmap["wordtype"].levels.toString());
  });

  module("TaskNode");

  test('TaskNode correctly extracts names of its inputs', function() {
    var fspec1, fspec2, fspec3, tspec;
    fspec1 = new Psy.FactorSpec(1, 1, "a", [1, 2, 3]);
    fspec2 = new Psy.FactorSpec(1, 1, "b", [5, 7, 9, 21]);
    fspec3 = new Psy.FactorSpec(1, 1, "dddd", [5, 7, 9, 21]);
    tspec = new Psy.TaskNode([fspec1, fspec2, fspec3], []);
    equal(["a", "b", "dddd"].toString(), tspec.factorNames.toString());
    return equal(tspec.varmap["a"].levels.toString(), [1, 2, 3].toString());
  });

  module("TaskSchema");

  test('can build a TaskSchema from object literal', function() {
    var schema, xs;
    schema = {
      main: {
        wordtype: {
          levels: ["word", "pseudo"]
        },
        repnum: {
          levels: [1, 2, 3, 4, 5, 6]
        },
        lag: {
          levels: [1, 2, 4, 8, 16, 32]
        }
      },
      aux: {
        novel: {
          levels: ["a", "b", "c"]
        },
        color: {
          levels: ["red", "green", "blue"]
        }
      }
    };
    xs = Psy.TaskSchema.build(schema);
    equal(["main", "aux"].toString(), xs.trialTypes());
    console.log("main schema factors", xs.factors("main"));
    return console.log("aux schema factors", xs.factors("aux"));
  });

  module("TrialList");

  test('can build a TrialList', function() {
    var tlist;
    tlist = new Psy.TrialList(6);
    tlist.add(0, {
      wordtype: "word",
      lag: 1,
      repnum: 1
    });
    tlist.add(0, {
      wordtype: "pseudo",
      lag: 2,
      repnum: 2
    });
    tlist.add(0, {
      wordtype: "word",
      lag: 4,
      repnum: 3
    });
    tlist.add(1, {
      wordtype: "word",
      lag: 2,
      repnum: 3
    });
    tlist.add(5, {
      wordtype: "word",
      lag: 2,
      repnum: 3
    });
    equal(tlist.ntrials(), 5);
    return console.log("TLIST", tlist.get(0, 2));
  });

  module("ItemNode");

  test('can build an ItemNode from object literal', function() {
    var inode, node;
    inode = {
      items: ["a", "b", "c"],
      attributes: {
        x: [1, 2, 3],
        y: [4, 5, 6]
      },
      type: "text"
    };
    node = Psy.ItemNode.build("inode", inode);
    equal(node.name, "inode");
    equal(node.attributes.x.toString(), [1, 2, 3].toString(), node.attributes.x.toString());
    return equal(node.attributes.y.toString(), [4, 5, 6].toString(), node.attributes.x.toString());
  });

  module("AbsoluteLayout");

  test('AbsoluteLayout correcty converts percentage to fraction', function() {
    var layout, xy;
    layout = new Psy.AbsoluteLayout();
    xy = layout.computePosition([1000, 1000], ["10%", "90%"]);
    equal(xy[0], 1000 * 0.10, "10% of 1000 is " + xy[0]);
    return equal(xy[1], 1000 * 0.90, "90% of 1000 is " + xy[1]);
  });

  test('AbsoluteLayout handles raw pixels', function() {
    var layout, xy;
    layout = new Psy.AbsoluteLayout();
    xy = layout.computePosition([1000, 1000], [10, 90]);
    equal(xy[0], 10);
    return equal(xy[1], 90);
  });

  module("Instructions");

  test('Can create an Instructions element', function() {
    var prelude;
    return prelude = {
      Prelude: {
        Instructions: {
          pages: {
            1: {
              MarkDown: "Welcome to the Experiment!\n=========================="
            },
            2: {
              Markdown: "Awesome!!!\n========================="
            }
          }
        }
      }
    };
  });

}).call(this);

/*
//@ sourceMappingURL=PsyCloud.test.map
*/
