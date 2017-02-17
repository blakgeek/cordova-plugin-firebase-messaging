var exec = require('cordova/exec');


function FirebaseMessagingPlugin() {

    var PLUGIN_NAME = "FirebaseMessagingPlugin";

    // FIRE READY //
    exec(dispatchEvent, null, PLUGIN_NAME, 'init', []);


    // GET TOKEN //
    this.getToken = function () {

        return new Promise(function (resolve, reject) {
            exec(resolve, reject, PLUGIN_NAME, 'getToken', []);
        });
    };

    // SUBSCRIBE TO TOPIC //
    this.subscribe = function (topic) {
        return new Promise(function (resolve, reject) {
            exec(resolve, reject, PLUGIN_NAME, 'subscribe', [topic]);
        });
    };

    // UNSUBSCRIBE FROM TOPIC //
    this.unsubscribe = function (topic) {
        return new Promise(function (resolve, reject) {
            exec(resolve, reject, PLUGIN_NAME, 'unsubscribe', [topic]);
        });
    };

    // trigger any queued events that would have fired prior to the app coming into the foreground
    this.flush = function() {

        exec(null, null, PLUGIN_NAME, 'flush', []);
    };


    function dispatchEvent(config) {

        var event = new Event(config.type);
        var prop;
        if (config.data) {
            for (prop in config.data) {
                event[prop] = config.data[prop];
            }
        }
        window.dispatchEvent(event);
    }
}


module.exports = FirebaseMessagingPlugin;
