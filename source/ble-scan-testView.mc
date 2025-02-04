import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.BluetoothLowEnergy;
import Toybox.StringUtil;
import Toybox.Lang;

class ble_scan_testView extends WatchUi.View {

    var scanResults as Dictionary<Number, BluetoothLowEnergy.ScanResult>;
    var currentSelection = 0;
    var currentMode = 0; // 0 = raw data, 1 = service data, 2 = manufacturerSpecificData

    var dataTextArea;

    function initialize() {
        View.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        BluetoothLowEnergy.setDelegate(new BleDelegate(self));
        BluetoothLowEnergy.setScanState(BluetoothLowEnergy.SCAN_STATE_SCANNING);
        dataTextArea = new WatchUi.TextArea({
            :locX => WatchUi.LAYOUT_HALIGN_CENTER,
            :locY => 30,
        });
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        var sr = scanResults.get(currentSelection);
        dc.drawText(dc.getWidth() / 2, 10, Graphics.FONT_TINY, sr.getDeviceName(), Graphics.TEXT_JUSTIFY_CENTER);

        dataTextArea.setWidth(dc.getWidth());
        dataTextArea.height = dc.getHeight() - 30;

        if(currentMode == 0) {
            dataTextArea.setText(hexToString(sr.getRawData()));
        }
        else if(currentMode == 1) {
            var serviceUuids = sr.getServiceUuids();
            var data = "";
            for(var uuid = serviceUuids.next() as BluetoothLowEnergy.Uuid; uuid != null; uuid = serviceUuids.next()) {
                var serviceData = sr.getServiceData(uuid);
                data += uuid.toString() + ":" + hexToString(serviceData) + "\n";
            }
            dataTextArea.setText(data);
        }
        else if(currentMode == 2) {
            var manufacturerSpecificData = sr.getManufacturerSpecificDataIterator();
            var data = "";
            for(var manufacturer = manufacturerSpecificData.next(); manufacturer != null; manufacturer = manufacturerSpecificData.next()) {
                data += manufacturer.companyId + ":" + hexToString(manufacturer.data) + "\n";
            }
            dataTextArea.setText(data);
        }


        dataTextArea.draw(dc);
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    function setScanResults(sr as BluetoothLowEnergy.Iterator) {
        for(var next = sr.next(); next != null; next = sr.next()) {
            scanResults.put(scanResults.size(), next);
        }
    }
 
    function previousScanResult() {
        currentSelection = (currentSelection - 1) % scanResults.size();
        requestUpdate();
    }

    function nextScanResult() {
        currentSelection = (currentSelection + 1) % scanResults.size();
        requestUpdate();
    }

    function switchMode() {
        currentMode = (currentMode + 1) % 3;
        requestUpdate();
    }

}

function hexToString(hex as ByteArray) {
    var options = {
        :fromRepresentation => StringUtil.REPRESENTATION_BYTE_ARRAY,
        :toRepresentation => StringUtil.REPRESENTATION_STRING_PLAIN_TEXT,
		:encoding => StringUtil.CHAR_ENCODING_UTF8
    };

    return StringUtil.convertEncodedString(hex, options);
}

class BleDelegate extends BluetoothLowEnergy.BleDelegate {
    private var _view;

    function initialize(view) {
        BleDelegate.initialize();
        _view = view;
    }

    function onScanResults(scanResults) {
        _view.setScanResults(scanResults);
    }
}

class Delegate extends BehaviorDelegate {
    private var _view;
    
    function initialize(view) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onMenu() {
        _view.switchMode();
    }

    function onNextMode() {
        _view.nextScanResult();
    }

    function onPreviousMode() {
        _view.previousScanResult();
    }
}