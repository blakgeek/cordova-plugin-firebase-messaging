var fs = require('fs');
var crypto = require('crypto');
var xcode = require('xcode');
var plist = require('plist');
var shell = require('shelljs');
var path = require('path');


module.exports = function (context) {

    // only execute for android
    if (!forPlatform('android')) return;

    var rootPath = context.opts.projectRoot;
    var googleServicesJsonSrcPath = path.join(rootPath, 'google-services.json');
    var googleServicesJsonDestPath = path.join(rootPath, 'platforms', 'android', 'google-services.json');
    var googleServicesJsonExists = fs.existsSync(googleServicesJsonSrcPath);
    var googleServicesJsonChanged = filesDiffer(googleServicesJsonSrcPath, googleServicesJsonDestPath);

    if (googleServicesJsonExists && googleServicesJsonChanged) {
        console.log('Copying google-services.json because the content changed.');
        shell.cp(googleServicesJsonSrcPath, googleServicesJsonDestPath);
    }

    function filesDiffer(a, b) {

        var aExists = fs.existsSync(a);
        var bExists = fs.existsSync(b);

        return !aExists || !bExists || hash(a) !== hash(b);
    }

    function forPlatform(platform) {

        return context.opts.platforms.indexOf(platform) > -1;
    }

    function hash(file) {

        var content = fs.readFileSync(file, 'utf8');
        return crypto.createHash('md5').update(content).digest('hex');
    }
};