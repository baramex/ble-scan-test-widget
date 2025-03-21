import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.BluetoothLowEnergy;
import Toybox.StringUtil;
import Toybox.Lang;

class ble_scan_testView extends WatchUi.View {
  var scanResults = ({}) as Dictionary<Number, BluetoothLowEnergy.ScanResult>;
  var currentSelection = 0;
  var currentMode = 0; // 0 = raw data, 1 = service data, 2 = manufacturerSpecificData, 3 = connect
  var currentDevice;

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
    BluetoothLowEnergy.setDelegate(new BleDelegateCustom(self));
    BluetoothLowEnergy.setScanState(BluetoothLowEnergy.SCAN_STATE_SCANNING);
    dataTextArea = new WatchUi.TextArea({
      :locX => WatchUi.LAYOUT_HALIGN_CENTER,
      :locY => 30,
      :font => Graphics.FONT_TINY,
      :color => Graphics.COLOR_WHITE,
      :text => "placeholder",
    });
  }

  // Update the view
  function onUpdate(dc as Dc) as Void {
    // Call the parent onUpdate function to redraw the layout
    View.onUpdate(dc);

    var sr = scanResults.get(currentSelection);
    if (sr == null) {
      return;
    }

    dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    var name;
    if (currentMode == 3 && currentDevice != null) {
      name = currentDevice.getName();
    } else {
      name = sr.getDeviceName();
    }
    if (name == null) {
      name = "Unknown";
    }
    name += " (" + (currentSelection + 1) + "/" + scanResults.size() + ")";
    dc.drawText(
      dc.getWidth() / 2,
      10,
      Graphics.FONT_TINY,
      name,
      Graphics.TEXT_JUSTIFY_CENTER
    );

    dataTextArea.width = dc.getWidth();
    dataTextArea.height = dc.getHeight() - 30;

    if (currentMode == 0) {
      dataTextArea.setText(sr.getRawData().toString());
    } else if (currentMode == 1) {
      var serviceUuids = sr.getServiceUuids();
      var data = "";
      if (serviceUuids != null && serviceUuids has :next) {
        for (
          var uuid = serviceUuids.next() as BluetoothLowEnergy.Uuid?;
          uuid != null;
          uuid = serviceUuids.next() as BluetoothLowEnergy.Uuid?
        ) {
          var serviceData = sr.getServiceData(uuid);
          data += uuid.toString();
          if (serviceData != null) {
            data += ":" + serviceData.toString();
          }
          data += "\n";
        }
      }
      dataTextArea.setText(data);
    } else if (currentMode == 2) {
      // IRREVELANT ..?
      var manufacturerSpecificData = sr.getManufacturerSpecificDataIterator();
      var data = "";
      if (
        manufacturerSpecificData != null &&
        manufacturerSpecificData has :next
      ) {
        for (
          var manufacturer = manufacturerSpecificData.next() as Dictionary?;
          manufacturer != null;
          manufacturer = manufacturerSpecificData.next() as Dictionary?
        ) {
          data += manufacturer.get("companyId"); // always null ?
          if (manufacturer.get("data") != null) {
            // also null ?
            data += ":" + manufacturer.get("data").toString();
          }
          data += "\n";
        }
      }
      dataTextArea.setText(data);
    } else if (currentMode == 3 && currentDevice != null) {
      var text = "Connected: " + currentDevice.isConnected();
      var services = currentDevice.getServices();
      var size = 0;
      for (var next = services.next(); next != null; next = services.next()) {
        size++;
      }
      text += "\nServices: " + size;
      dataTextArea.setText(text);
    }

    dataTextArea.draw(dc);
  }

  // Called when this View is removed from the screen. Save the
  // state of this View here. This includes freeing resources from
  // memory.
  function onHide() as Void {
    BluetoothLowEnergy.setScanState(BluetoothLowEnergy.SCAN_STATE_OFF);
  }

  function setScanResults(sr as BluetoothLowEnergy.Iterator) {
    var bl = scanResults.size();
    for (
      var next = sr.next() as BluetoothLowEnergy.ScanResult?;
      next != null;
      next = sr.next()
    ) {
      var hasDevice = false;
      for (var i = 0; i < scanResults.size(); i++) {
        if (scanResults.get(i).isSameDevice(next)) {
          hasDevice = true;
          break;
        }
      }
      if (hasDevice == true) {
        continue;
      }
      scanResults.put(scanResults.size(), next);
    }
    if (bl != scanResults.size()) {
      requestUpdate();
    }
  }

  function previousScanResult() {
    currentSelection = currentSelection - 1;
    if (currentSelection < 0) {
      currentSelection = scanResults.size() - 1;
    }
    currentMode = 0;
    System.println("Scan result " + currentSelection);
    requestUpdate();
  }

  function nextScanResult() {
    currentSelection = (currentSelection + 1) % scanResults.size();
    currentMode = 0;
    System.println("Scan result " + currentSelection);
    requestUpdate();
  }

  function switchMode() {
    currentMode = (currentMode + 1) % 4;
    if (currentMode == 3) {
      currentDevice = BluetoothLowEnergy.pairDevice(
        scanResults.get(currentSelection)
      );
    } else if (currentDevice != null) {
      BluetoothLowEnergy.unpairDevice(currentDevice);
      currentDevice = null;
    }
    System.println("Mode " + currentMode);
    requestUpdate();
  }

  function updateDevice(device) {
    currentDevice = device;
    requestUpdate();
  }
}

function hexToString(hex as ByteArray) {
  var text = "";
  for (var i = 0; i < hex.size(); i++) {
    text += hex[i].toChar().toString();
  }
  return text;
}

class BleDelegateCustom extends BluetoothLowEnergy.BleDelegate {
  private var _view;

  function initialize(view) {
    BleDelegate.initialize();
    _view = view;
  }

  function onScanResults(scanResults) {
    _view.setScanResults(scanResults);
  }

  function onConnectedStateChanged(
    device as BluetoothLowEnergy.Device,
    state as BluetoothLowEnergy.ConnectionState
  ) {
    _view.updateDevice(device);
  }
}

class Delegate extends WatchUi.BehaviorDelegate {
  private var _view;

  function initialize(view) {
    BehaviorDelegate.initialize();
    _view = view;
  }

  function onSelect() {
    _view.switchMode();
    return true;
  }

  function onNextPage() {
    _view.nextScanResult();
    return true;
  }

  function onPreviousPage() {
    _view.previousScanResult();
    return true;
  }
}
