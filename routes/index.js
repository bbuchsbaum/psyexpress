
/*
 * GET home page.
 */


exports.index = function(req, res){
    res.render('index', {
        scripts: ['/javascripts/hello.js', '/javascripts/psycloud.js'],
        title: 'Express'
    });
};