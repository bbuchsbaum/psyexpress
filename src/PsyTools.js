// Generated by CoffeeScript 1.4.0
(function() {
  var ConditionalSampler, CrossedFactorSpec, DataTable, ExhaustiveSampler, ExpDesign, Experiment, ExperimentContext, Factor, FactorSpec, ItemSet, Sampler, UniformSampler, VarSpec, asArray, f1, f2, f3, rep, _,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __slice = [].slice;

  _ = require('lodash');

  asArray = function(value) {
    if (_.isArray(value)) {
      return value;
    } else if (_.isNumber(value) || _.isBoolean(value)) {
      return [value];
    } else {
      return _.toArray(value);
    }
  };

  rep = function(vec, times) {
    var el, i, j, out,
      _this = this;
    if (!(times instanceof Array)) {
      times = [times];
    }
    if (times.length !== 1 && vec.length !== times.length) {
      console.log("vec", vec);
      console.log("times", times);
      throw "vec.length must equal times.length or times.length must be 1";
    }
    if (vec.length === times.length) {
      out = (function() {
        var _i, _len, _results;
        _results = [];
        for (i = _i = 0, _len = vec.length; _i < _len; i = ++_i) {
          el = vec[i];
          _results.push((function() {
            var _j, _ref, _results1;
            _results1 = [];
            for (j = _j = 1, _ref = times[i]; 1 <= _ref ? _j <= _ref : _j >= _ref; j = 1 <= _ref ? ++_j : --_j) {
              _results1.push(el);
            }
            return _results1;
          })());
        }
        return _results;
      })();
      return _.flatten(out);
    } else {
      out = _.times(times[0], function(n) {
        return vec;
      });
      return _.flatten(out);
    }
  };

  exports.rep = rep;

  exports.Sampler = Sampler = (function() {

    function Sampler(items) {
      this.items = items;
    }

    Sampler.prototype.take = function(n) {
      if (n > this.items.length) {
        throw "cannot take sample larger than the number of items when using non-replacing sampler";
      }
      return _.shuffle(this.items).slice(0, n);
    };

    return Sampler;

  })();

  exports.ExhaustiveSampler = ExhaustiveSampler = (function() {

    ExhaustiveSampler.fillBuffer = function(items, n) {
      var buf, i;
      buf = (function() {
        var _i, _results;
        _results = [];
        for (i = _i = 1; 1 <= n ? _i <= n : _i >= n; i = 1 <= n ? ++_i : --_i) {
          _results.push(_.shuffle(items));
        }
        return _results;
      })();
      return _.flatten(buf);
    };

    function ExhaustiveSampler(items, buflen) {
      this.items = items;
      if (buflen == null) {
        buflen = 10;
      }
      this.buffer = ExhaustiveSampler.fillBuffer(this.items, buflen);
    }

    ExhaustiveSampler.prototype.take = function(n) {
      var buf, buflen, res;
      if (n <= this.buffer.length) {
        res = _.take(this.buffer, n);
        this.buffer = _.drop(this.buffer, n);
        return res;
      } else {
        buflen = Math.max(n, 10 * this.items.length);
        buf = ExhaustiveSampler.fillBuffer(this.items, buflen / this.items.length);
        return this.buffer = this.buffer.concat(buf);
      }
    };

    return ExhaustiveSampler;

  })();

  exports.UniformSampler = UniformSampler = (function(_super) {

    __extends(UniformSampler, _super);

    UniformSampler.validate = function(range) {
      if (range.length !== 2) {
        throw "range must be an array with two values (min, max)";
      }
      if (range[1] <= range[0]) {
        throw "range[1] must > range[0]";
      }
    };

    function UniformSampler(range) {
      this.range = range;
      this.interval = this.range[1] - this.range[0];
    }

    UniformSampler.prototype.take = function(n) {
      var i, nums;
      nums = (function() {
        var _i, _results;
        _results = [];
        for (i = _i = 1; 1 <= n ? _i <= n : _i >= n; i = 1 <= n ? ++_i : --_i) {
          _results.push(Math.round(Math.random() * this.interval));
        }
        return _results;
      }).call(this);
      return nums;
    };

    return UniformSampler;

  })(Sampler);

  exports.ConditionalSampler = ConditionalSampler = (function(_super) {

    __extends(ConditionalSampler, _super);

    function ConditionalSampler(keyMap) {
      var key, value, _ref;
      this.keyMap = keyMap;
      this.samplerSet = {};
      _ref = this.keyMap;
      for (key in _ref) {
        value = _ref[key];
        console.log("key: ", key);
        console.log("value: ", value);
        this.samplerSet[key] = new ExhaustiveSampler(value);
      }
      console.log(_.keys(this.samplerSet));
    }

    ConditionalSampler.prototype.take = function(n) {};

    ConditionalSampler.prototype.take = function(key, n) {
      return this.samplerSet[key].take(n);
    };

    return ConditionalSampler;

  })(Sampler);

  exports.Factor = Factor = (function(_super) {

    __extends(Factor, _super);

    Factor.asFactor = function(arr) {
      return (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return Object(result) === result ? result : child;
      })(Factor, arr, function(){});
    };

    function Factor(arr) {
      var arg, _i, _len;
      for (_i = 0, _len = arr.length; _i < _len; _i++) {
        arg = arr[_i];
        this.push(arg);
      }
      this.levels = _.uniq(arr).sort();
    }

    return Factor;

  })(Array);

  exports.DataTable = DataTable = (function() {

    DataTable.prototype.show = function() {
      var i, _i, _ref, _results;
      console.log("DataTable: rows: " + (this.nrow()) + " columns: " + (this.ncol()));
      _results = [];
      for (i = _i = 0, _ref = this.nrow(); 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        _results.push(console.log(this.record(i)));
      }
      return _results;
    };

    DataTable.build = function(vars) {
      if (vars == null) {
        vars = {};
      }
      return Object.seal(new DataTable(vars));
    };

    DataTable.expand = function(vars, unique, nreps) {
      var d, i, key, name, nargs, nm, nx, orep, out, r1, r2, r3, repfac, value, _i, _results;
      if (vars == null) {
        vars = {};
      }
      if (unique == null) {
        unique = true;
      }
      if (nreps == null) {
        nreps = 1;
      }
      if (unique) {
        out = {};
        for (name in vars) {
          value = vars[name];
          out[name] = _.unique(value);
        }
        vars = out;
      }
      nargs = _.size(vars);
      nm = _.keys(vars);
      repfac = 1;
      d = _.map(vars, function(x) {
        return x.length;
      });
      orep = _.reduce(d, function(x, acc) {
        return x * acc;
      });
      out = {};
      for (key in vars) {
        value = vars[key];
        nx = value.length;
        orep = orep / nx;
        r1 = rep([repfac], nx);
        r2 = rep((function() {
          _results = [];
          for (var _i = 0; 0 <= nx ? _i < nx : _i > nx; 0 <= nx ? _i++ : _i--){ _results.push(_i); }
          return _results;
        }).apply(this), r1);
        r3 = rep(r2, orep);
        out[key] = (function() {
          var _j, _len, _results1;
          _results1 = [];
          for (_j = 0, _len = r3.length; _j < _len; _j++) {
            i = r3[_j];
            _results1.push(value[i]);
          }
          return _results1;
        })();
        repfac = repfac * nx;
      }
      return new DataTable(out);
    };

    function DataTable(vars) {
      var key, samelen, value, varlen;
      if (vars == null) {
        vars = {};
      }
      varlen = _.map(vars, function(x) {
        return x.length;
      });
      samelen = _.all(varlen, function(x) {
        return x === varlen[0];
      });
      if (!samelen) {
        throw "arguments to DataTable must all have same length.";
      }
      for (key in vars) {
        value = vars[key];
        this[key] = value;
      }
    }

    DataTable.prototype.subset = function(key, filter) {
      var el, i, keep, name, out, val, value;
      keep = (function() {
        var _i, _len, _ref, _results;
        _ref = this[key];
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          val = _ref[_i];
          if (filter(val)) {
            _results.push(true);
          } else {
            _results.push(false);
          }
        }
        return _results;
      }).call(this);
      out = {};
      for (name in this) {
        if (!__hasProp.call(this, name)) continue;
        value = this[name];
        out[name] = (function() {
          var _i, _len, _results;
          _results = [];
          for (i = _i = 0, _len = value.length; _i < _len; i = ++_i) {
            el = value[i];
            if (keep[i] === true) {
              _results.push(el);
            }
          }
          return _results;
        })();
      }
      return new DataTable(out);
    };

    DataTable.prototype.whichRow = function(where) {
      var count, i, key, nkeys, out, rec, value, _i, _ref;
      out = [];
      nkeys = _.keys(where).length;
      for (i = _i = 0, _ref = this.nrow(); 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        rec = this.record(i);
        count = asArray((function() {
          var _results;
          _results = [];
          for (key in where) {
            value = where[key];
            _results.push(rec[key] === value);
          }
          return _results;
        })());
        count = _.map(count, function(x) {
          if (x) {
            return 1;
          } else {
            return 0;
          }
        });
        count = _.reduce(asArray(count), function(sum, num) {
          return sum + num;
        });
        if (count === nkeys) {
          out.push(i);
        }
      }
      return out;
    };

    DataTable.prototype.select = function(where) {
      var count, i, key, nkeys, out, rec, value, _i, _ref;
      out = [];
      nkeys = _.keys(where).length;
      for (i = _i = 0, _ref = this.nrow(); 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        rec = this.record(i);
        count = asArray((function() {
          var _results;
          _results = [];
          for (key in where) {
            value = where[key];
            _results.push(rec[key] === value);
          }
          return _results;
        })());
        count = _.map(count, function(x) {
          if (x) {
            return 1;
          } else {
            return 0;
          }
        });
        count = _.reduce(asArray(count), function(sum, num) {
          return sum + num;
        });
        if (count === nkeys) {
          out.push(rec);
        }
      }
      return out;
    };

    DataTable.prototype.nrow = function() {
      var lens, name, value;
      lens = (function() {
        var _results;
        _results = [];
        for (name in this) {
          if (!__hasProp.call(this, name)) continue;
          value = this[name];
          _results.push(value.length);
        }
        return _results;
      }).call(this);
      return _.max(lens);
    };

    DataTable.prototype.ncol = function() {
      return Object.keys(this).length;
    };

    DataTable.prototype.colnames = function() {
      return Object.keys(this);
    };

    DataTable.prototype.record = function(index) {
      var name, rec, value;
      rec = {};
      for (name in this) {
        if (!__hasProp.call(this, name)) continue;
        value = this[name];
        rec[name] = value[index];
      }
      return rec;
    };

    DataTable.prototype.replicate = function(nreps) {
      var name, out, value,
        _this = this;
      out = {};
      for (name in this) {
        if (!__hasProp.call(this, name)) continue;
        value = this[name];
        out[name] = _.flatten(_.times(nreps, function(n) {
          return value;
        }));
      }
      return new DataTable(out);
    };

    DataTable.prototype.bindcol = function(name, column) {
      if (column.length !== this.nrow()) {
        throw "new column must be same length as existing DataTable object: column.length is  " + column.length + " and this.length is  " + (this.nrow());
      }
      this[name] = column;
      return this;
    };

    DataTable.prototype.bindrow = function(rows) {
      var key, record, value, _i, _len;
      if (!_.isArray(rows)) {
        rows = [rows];
      }
      for (_i = 0, _len = rows.length; _i < _len; _i++) {
        record = rows[_i];
        console.log(record);
        for (key in record) {
          if (!__hasProp.call(record, key)) continue;
          value = record[key];
          if (!_.has(this, key)) {
            throw "DataTable has no field named " + key;
          } else {
            this[key].push(value);
          }
        }
      }
      return this;
    };

    return DataTable;

  })();

  exports.ItemSet = ItemSet = (function() {

    function ItemSet(items, attributes, samplerFactory) {
      var unique;
      this.items = items;
      this.attributes = attributes;
      this.samplerFactory = samplerFactory;
      this.attributeSet = DataTable.expand(this.attributes, unique = true);
      this.attributeSet.show();
    }

    return ItemSet;

  })();

  exports.ExperimentContext = ExperimentContext = (function() {

    function ExperimentContext() {}

    ExperimentContext.block = 0;

    ExperimentContext.trial = 0;

    return ExperimentContext;

  })();

  exports.Experiment = Experiment = (function() {

    function Experiment(designSpec) {
      this.designSpec = designSpec;
      this.design = new ExpDesign(this.designSpec);
      this.display = this.designSpec["Display"];
      this.trialGenerator = this.display["Trial"];
      console.log(this.display);
    }

    Experiment.prototype.start = function(context) {
      var gentrial, i, numBlocks, trial, trials, _i, _ref, _results;
      this.context = context;
      numBlocks = this.design.blocks;
      trials = this.design.blockTrials(0);
      console.log(trials.nrow());
      _results = [];
      for (i = _i = 0, _ref = trials.nrow(); 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        console.log(trials.record(i));
        trial = trials.record(i);
        _results.push(gentrial = this.trialGenerator(trial));
      }
      return _results;
    };

    return Experiment;

  })();

  exports.VarSpec = VarSpec = (function() {

    function VarSpec() {}

    VarSpec.name = "";

    VarSpec.nblocks = 1;

    VarSpec.reps = 1;

    VarSpec.expanded = {};

    VarSpec.prototype.ntrials = function() {
      return this.nblocks * this.reps;
    };

    VarSpec.prototype.valueAt = function(block, trial) {};

    return VarSpec;

  })();

  exports.FactorSpec = FactorSpec = (function(_super) {

    __extends(FactorSpec, _super);

    function FactorSpec(nblocks, reps, name, levels) {
      this.nblocks = nblocks;
      this.reps = reps;
      this.name = name;
      this.levels = levels;
      this.expanded = this.expand(this.nblocks, this.reps);
    }

    FactorSpec.prototype.cross = function(other) {
      return new CrossedFactorSpec(this.nblocks, this.reps, this, other);
    };

    FactorSpec.prototype.expand = function(nblocks, reps) {
      var i, prop, vset, _i, _results;
      prop = {};
      prop[this.name] = this.levels;
      vset = new DataTable(prop);
      _results = [];
      for (i = _i = 1; 1 <= nblocks ? _i <= nblocks : _i >= nblocks; i = 1 <= nblocks ? ++_i : --_i) {
        _results.push(vset.replicate(reps));
      }
      return _results;
    };

    FactorSpec.prototype.valueAt = function(block, trial) {
      return this.expanded[block][this.name][trial];
    };

    return FactorSpec;

  })(VarSpec);

  exports.CrossedFactorSpec = CrossedFactorSpec = (function(_super) {

    __extends(CrossedFactorSpec, _super);

    function CrossedFactorSpec() {
      var fac, nblocks, parents, reps;
      nblocks = arguments[0], reps = arguments[1], parents = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
      this.nblocks = nblocks;
      this.reps = reps;
      this.parents = parents;
      this.parentNames = (function() {
        var _i, _len, _ref, _results;
        _ref = this.parents;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          fac = _ref[_i];
          _results.push(fac.name);
        }
        return _results;
      }).call(this);
      this.name = _.reduce(this.parentNames, function(n, n1) {
        return n + ":" + n1;
      });
      this.levels = (function() {
        var _i, _len, _ref, _results;
        _ref = this.parents;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          fac = _ref[_i];
          _results.push(fac.levels);
        }
        return _results;
      }).call(this);
      this.factorSet = _.zipObject(this.parentNames, this.levels);
      this.table = DataTable.expand(this.factorSet);
      this.expanded = this.expand(this.nblocks, this.reps);
    }

    CrossedFactorSpec.prototype.expand = function(nblocks, reps) {
      var i, _i, _results;
      _results = [];
      for (i = _i = 1; 1 <= nblocks ? _i <= nblocks : _i >= nblocks; i = 1 <= nblocks ? ++_i : --_i) {
        _results.push(this.table.replicate(reps));
      }
      return _results;
    };

    CrossedFactorSpec.prototype.valueAt = function(block, trial) {
      var name, _i, _len, _ref, _results;
      _ref = this.parentNames;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        name = _ref[_i];
        _results.push(this.expanded[block][name][trial]);
      }
      return _results;
    };

    return CrossedFactorSpec;

  })(VarSpec);

  exports.ExpDesign = ExpDesign = (function() {

    ExpDesign.blocks = 1;

    ExpDesign.prototype.blockTrials = function(blocknum) {
      return this.design[blocknum];
    };

    ExpDesign.prototype.ncells = function(includeBlock) {
      if (includeBlock == null) {
        includeBlock = false;
      }
      if (includeBlock) {
        return this.crossedCells.nrow() * this.blocks;
      } else {
        return this.crossedCells.nrow();
      }
    };

    ExpDesign.prototype.ntrials = function(byBlock) {
      var blen;
      if (byBlock == null) {
        byBlock = false;
      }
      blen = _.map(this.design, function(x) {
        return x.nrow();
      });
      if (byBlock) {
        return blen;
      } else {
        return _.reduce(blen, function(sum, num) {
          return sum + num;
        });
      }
    };

    ExpDesign.prototype.crossVariables = function(vars) {
      return DataTable.expand(vars);
    };

    ExpDesign.validate = function(spec) {
      var des;
      if (!("Design" in spec)) {
        throw "Design is undefined";
      }
      des = spec["Design"];
      if (!("Variables" in des)) {
        throw "Variables is undefined";
      }
      if (!("Structure" in des)) {
        throw "Structure is undefined";
      }
      if (!("Items" in spec)) {
        throw "Items is undefined";
      }
    };

    ExpDesign.expandBlocks = function() {
      var i, nblocks, reps, res, vars, vset;
      nblocks = arguments[0], reps = arguments[1], vars = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
      res = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = vars.length; _i < _len; _i++) {
          vset = vars[_i];
          _results.push((function() {
            var _j, _results1;
            _results1 = [];
            for (i = _j = 1; 1 <= nblocks ? _j <= nblocks : _j >= nblocks; i = 1 <= nblocks ? ++_j : --_j) {
              _results1.push(vset.replicate(reps));
            }
            return _results1;
          })());
        }
        return _results;
      })();
      return console.log(res);
    };

    ExpDesign.splitCrossedItems = function(itemSpec, crossedVariables) {
      var attrnames, conditionTable, i, indices, itemSets, j, keySet, levs, record, values;
      attrnames = crossedVariables.colnames();
      keySet = (function() {
        var _i, _ref, _results;
        _results = [];
        for (i = _i = 0, _ref = crossedVariables.nrow(); 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
          record = crossedVariables.record(i);
          levs = _.values(record);
          _results.push(_.reduce(levs, (function(a, b) {
            return a + ":" + b;
          })));
        }
        return _results;
      })();
      values = itemSpec["values"];
      conditionTable = new DataTable(_.pick(itemSpec, attrnames));
      itemSets = (function() {
        var _i, _ref, _results;
        _results = [];
        for (i = _i = 0, _ref = crossedVariables.nrow(); 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
          record = crossedVariables.record(i);
          indices = conditionTable.whichRow(record);
          _results.push((function() {
            var _j, _len, _results1;
            _results1 = [];
            for (_j = 0, _len = indices.length; _j < _len; _j++) {
              j = indices[_j];
              _results1.push(values[j]);
            }
            return _results1;
          })());
        }
        return _results;
      })();
      return _.zipObject(keySet, itemSets);
    };

    ExpDesign.makeSampler = function() {};

    ExpDesign.prototype.getCrossedVars = function(variables) {
      var crossed, crossedVars, key, value;
      this.variables = variables;
      crossed = this.variables["Crossed"];
      crossedVars = {};
      for (key in crossed) {
        value = crossed[key];
        if (value["type"] === "Factor") {
          crossedVars[key] = value["levels"];
        }
      }
      return crossedVars;
    };

    function ExpDesign(spec) {
      var crossedItemName, crossedItemSets, crossedItems, reps;
      if (spec == null) {
        spec = {};
      }
      ExpDesign.validate(spec);
      this.design = spec["Design"];
      this.variables = this.design["Variables"];
      this.itemSpec = spec["Items"];
      console.log("creating design");
      this.structure = this.design["Structure"];
      this.varnames = _.keys(this.variables);
      this.crossed = this.variables["Crossed"];
      this.auxiliary = this.variables["Auxiliary"];
      this.crossedVars = this.getCrossedVars(this.variables);
      this.crossedCells = this.crossVariables(this.crossedVars);
      crossedItems = this.itemSpec["Crossed"];
      crossedItemName = _.keys(crossedItems)[0];
      crossedItemSets = ExpDesign.splitCrossedItems(crossedItems[crossedItemName], this.crossedCells);
      this.crossedSampler = new ConditionalSampler(crossedItemSets);
      console.log(this.crossedSampler.take("word:1", 32));
      if (this.structure["type"] === "Block") {
        if (!_.has(this.structure, "reps_per_block")) {
          this.structure["reps_per_block"] = 1;
        }
        reps = this.structure["reps_per_block"];
        this.blocks = this.structure["blocks"];
        this.x = ExpDesign.expandBlocks(this.blocks, reps, this.crossedCells);
        console.log(this.x);
      }
      console.log(this.crossedDesign);
    }

    return ExpDesign;

  })();

  this.LexDesign = {
    Design: {
      Variables: {
        Crossed: {
          wordtype: {
            type: "Factor",
            levels: ["word", "nonword"]
          },
          syllables: {
            type: "Factor",
            levels: [1, 2]
          }
        },
        Auxiliary: {
          isi: {
            type: "Continuous"
          }
        }
      },
      Structure: {
        type: "Block",
        blocks: 8,
        reps_per_block: 4
      }
    },
    Items: {
      Crossed: {
        words: {
          values: ["hello", "goodbye", "flirg", "schmirt", "black", "sweetheart", "grum", "snirg", "snake", "pet", "hirble", "kerble"],
          wordtype: ["word", "word", "nonword", "nonword", "word", "word", "nonword", "nonword", "word", "word", "nonword", "nonword"],
          syllables: [2, 2, 1, 1, 1, 2, 1, 1, 1, 1, 2, 2],
          sampler: {
            type: "Exhaustive"
          }
        }
      },
      Auxiliary: {
        isi: {
          sampler: {
            type: "Uniform",
            min: 300,
            max: 3000
          }
        }
      }
    },
    Display: {
      Trial: function(trial) {
        return {
          1: {
            FixationCross: {
              length: 100,
              strokeWidth: 5
            },
            Next: {
              Timeout: trial.isi
            }
          },
          2: {
            Text: {
              x: 0,
              y: 0,
              content: trial.word
            },
            Next: {
              KeyPressed: {
                keys: ['a', 'b'],
                correct: trial.wordtype === "word" ? 'a' : 'b',
                maxDuration: 3000,
                minDuration: 500
              }
            }
          }
        };
      }
    }
  };

  f1 = new FactorSpec(5, 3, "wordtype", ["word", "nonword"]);

  f2 = new FactorSpec(5, 3, "syllables", [1, 2]);

  f3 = f1.cross(f2);

  console.log(f3.expanded);

  console.log(f1.ntrials());

  console.log(f3.valueAt(1, 3));

}).call(this);
