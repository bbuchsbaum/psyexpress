
/*
 * GET home page.
 */


exports.index = function(req, res){
    res.render('index', {
        scripts: ['/javascripts/hello.js', '/javascripts/PsyCloud.js'],
        title: 'Express'
    });
};