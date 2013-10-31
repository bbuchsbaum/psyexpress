
/**
 * Module dependencies.
 */

var express = require('express')
  , routes = require('./routes')
  , user = require('./routes/user')
  , http = require('http')
  , path = require('path')

var redux = require("coffee-script-redux")

var app = express();

app.configure(function(){
  app.set('port', 3000);
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.favicon());
  app.use(express.logger('dev'));
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(app.router);
  app.use(require('less-middleware')({ src: __dirname + '/public' }));
  app.use(express.static(path.join(__dirname, 'public')));
  app.use(express.static(path.join(__dirname, 'public/tasks/LexDecision')));
  app.use(express.static(path.join(__dirname, 'public/tasks/LexDecision/resources')));

});

app.configure('development', function(){
  app.use(express.errorHandler());
});

app.get('/', routes.index);
app.get('/users', user.list);


app.post('/test-page', function(req, res) {
    console.log("req", req.body.code);
    var result = redux.parse(req.body.code);
    var jsAST = redux.compile(result);
    var jsout = redux.jsWithSourceMap(jsAST);
    console.log(jsout);
    console.log("sending", jsout.code);
    res.send(jsout.code);
});


//http.createServer(app).listen(process.env.PORT, process.env.IP, function(){
//  console.log("Express server listening on port " + app.get('port'));
// });

http.createServer(app).listen(3000, function(){
      console.log("Express server listening on port " + app.get('port'));
});



