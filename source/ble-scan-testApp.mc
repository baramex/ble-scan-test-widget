import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class ble_scan_testApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new ble_scan_testView();
        return [ view, new Delegate(view) ];
    }

}

function getApp() as ble_scan_testApp {
    return Application.getApp() as ble_scan_testApp;
}