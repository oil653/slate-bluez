import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Widgets

Scope{
    id: root;

    property string configPath: "config/slate-bluez.json"

    // Bluetooth property bindings
    property bool adapterOn;
    property bool isScanning;

    Timer {  // We need this because the bluetooth module loads in async
        id: initTimer  
        interval: 100  
        running: true  
        repeat: true  
        onTriggered: {  
            if (Bluetooth.defaultAdapter) {  
                root.adapterOn = Bluetooth.defaultAdapter.enabled;  
                root.isScanning = Bluetooth.defaultAdapter.discovering;  
                running = false; // Stop polling once initialized  
            }  
        }  
    }

    
    
    // Using fileview to read and serialize the config
    FileView{
        id: conifgFile;
        path: root.configPath;

        watchChanges: true;
        preload: true;
        
        onFileChanged: {
            reload();
            console.log("Config file changed, reloading adapter")
        }
        onAdapterUpdated: {
            writeAdapter();
            console.log("Adapter updated, writing adapter to file");
        }

         // If file is empty it writes the defaults  
        onLoaded: {
            if (data().length === 0 || text().trim() === "" || text().trim() === "{}") {  
                console.log("Config file is empty, writing defaults");  
                writeAdapter();  
            }  
        }  
        
        // If file doesnt exists it tries to create a new one with the default parameters in it
        onLoadFailed: function(error) {  
            if (error === FileViewError.FileNotFound) {  
                console.log("Config file not found, creating with defaults");  
                writeAdapter();  
            }  
        }  
        
        JsonAdapter {
            id: config;
            // DO NOT EDIT THE VALUES HERE BUT IN THE CONFIG FILE!!
            
            // About the main window
            property real height: 320;
            property real width: 350; // 350 < x < 400
                // anchor points 
            property bool anchorTop: false;
            property bool anchorBottom: true;
            property bool anchorLeft: false;
            property bool anchorRight: true;
                // Margin from the side of the screen
            property real marginTop: 0;
            property real marginBottom: 200;
            property real marginLeft: 0; 
            property real marginRight: 0;
                // Padding
            property real topLeftRadius: 20;
            property real topRightRadius: 20;
            property real bottomLeftRadius: 20;
            property real bottomRightRadius: 20;

            // Colors
                // The background of the bottom panel
            property string bgColor: "#2d2a30";
                // The background of the top panel
            property string topBgColor: "#2a282b";
                // Device entry bg color
            property string entryColor: "#858585"
                // Font color
            property string fontColor: "#e2e2e2"

            // misc

        }
        
    }

    Process{ // runs "rfkill unblock bluetooth"
        id: rfkillProcess
        running: false;
        command: ["rfkill", "unblock", "bluetooth"];
        stderr: StdioCollector{
            onStreamFinished: {
                console.log("rfkill returned: " + this.text)
            }
        }
    }

    FontLoader{
        id: icelandFont;
        source: "root:/fonts/Iceland-Regular.ttf"
    }

    PanelWindow{
        id: rootPanel;
        implicitHeight: config.height;
        implicitWidth: config.width;
        anchors {
            top: config.anchorTop;
            bottom: config.anchorBottom;
            left: config.anchorLeft;
            right: config.anchorRight;
        }
        margins.top:config.marginTop;
        margins.bottom:config.marginBottom;
        margins.left:config.marginLeft;
        margins.right:config.marginRight;


        color: "transparent";
        Rectangle{
            id: bg;
            anchors.fill: parent;
            color: config.bgColor;
            topLeftRadius: config.topLeftRadius;
            topRightRadius: config.topRightRadius;
            bottomLeftRadius: config.bottomLeftRadius;
            bottomRightRadius: config.bottomRightRadius;

            Rectangle{ // Top control panel
                id: topPanel;
                anchors.horizontalCenter: parent.horizontalCenter;
                anchors.top: parent.top;
                implicitWidth: parent.width;
                implicitHeight: parent.height / 5
                topLeftRadius: config.topLeftRadius
                topRightRadius: config.topRightRadius
                color: config.topBgColor;
                ColumnLayout {
                    anchors.fill: parent;
                    
                    RowLayout{ 
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop;
                        spacing: rootPanel.width / 30;
                        Layout.topMargin: 8;
                        Text{
                            id: slateText
                            text: "<b>SLATE BLUEZ</b>"
                            font.pointSize: 28;
                            color: "grey";
                            font.family: icelandFont.name;
                        }
                        ToggleButton{ // adapter power button
                            buttonId: "powerToggle";
                            width: rootPanel.width /6.5;
                            showIcon: true;
                            iconOffPath: "root:/icons/bluetooth_white.svg"
                            isOn: root.adapterOn;
                            onIsOnChanged: {
                                Bluetooth.defaultAdapter.enabled = isOn
                            }
                        }
                        ToggleButton{ // Discovering
                            width: rootPanel.width /6.5;
                            buttonId: "discoverToggle";
                            showIcon: true;
                            iconOffPath: "root:/icons/scanning_white.svg"
                            isOn: root.isScanning;
                            onIsOnChanged: {
                                Bluetooth.defaultAdapter.discovering = isOn;
                            }
                        }
                    }
                }
            } // top closing

        
            ClippingWrapperRectangle{ // Devices panel
                id: bottomPanel;
                anchors.top: topPanel.bottom;
                anchors.horizontalCenter: rootPanel.horizontalCenter;
                
                height: rootPanel.height - topPanel.height;
                width: rootPanel.width;
                bottomLeftRadius: config.bottomLeftRadius;
                bottomRightRadius: config.bottomRightRadius;
                
                color: "transparent";

                ScrollView{
                    anchors.fill: parent;
                    Column{
                        anchors.fill: parent;
                        spacing: 5;
                        Repeater{
                            model: Bluetooth.devices;
                            // model: 10
                            Rectangle {
                                id: deviceEntry;
                                property var device: modelData;
                                height: 65;
                                width: bottomPanel.width;
                                color: config.entryColor;
                                Row{
                                    anchors.fill: parent;
                                    anchors.leftMargin: 5
                                    spacing: 8
                                    /* Rectangle{ // There should be an icon here, wip
                                        id: entryIcon;
                                        width: 65;
                                        height: 65;
                                    } */
                                    IconImage{
                                        id: entryIcon;
                                        implicitSize: deviceEntry.height;
                                        source: `root:/icons/device_icons/${(deviceEntry.device.icon != "") ? deviceEntry.device.icon : "unknown" }`;
                                    }
                                    Column{
                                        id: entryInfo;
                                        spacing: 0
                                        Text{
                                            text: `<b>${deviceEntry.device.name}</b>`;
                                            font.pointSize: 14
                                        }
                                        Text{
                                            text: `<i>${deviceEntry.device.address}</i>`; // device mac
                                            font.pointSize: 9;
                                        }
                                        Row{
                                            id: entryIcons;
                                            IconImage{ // Displayed if the device is trusted
                                                source: deviceEntry.device.trusted ? "root:/icons/trusted.svg" : (deviceEntry.device.blocked) ? "root:/icons/blocked.svg" : "";
                                                implicitSize: 20;
                                            }
                                            IconImage{ // Displayed if the device is connected
                                                source: deviceEntry.device.connected ? "root:/icons/connected.svg" : "";
                                                implicitSize: 18;
                                            }
                                            IconImage{ // Displayed if battery for device is available
                                                source: deviceEntry.device.batteryAvailable ? "root:/icons/battery.svg" : "";
                                                implicitSize: 18;
                                            }
                                            Text{ // Displayed if battery available
                                                text: (deviceEntry.device.batteryAvailable) ? `<b>${deviceEntry.device.battery * 100}%</b>` : "";
                                                font.pointSize: 12;
                                                // font.family: icelandFont.name;
                                            }
                                        }
                                    }
                                    Row{ // Connect, trust, block
                                    }
                                }
                            }
                        }
                    }
                }
            }

            /* Rectangle{ // Debug button, it overwrites all config with the default properties
                anchors.bottom: parent.bottom;
                anchors.horizontalCenter: parent.horizontalCenter
                width: 30;
                height: 40;
                MouseArea{
                    anchors.fill: parent;
                    onClicked: {
                        conifgFile.writeAdapter();
                        console.log("Config overwritten");
                    }
                }
            } */
        }

        /* Rectangle{ // Debug button, it gets the rfkill popup up
                anchors.bottom: parent.bottom;
                width: 30;
                height: 40;
                color: "red"
                MouseArea{
                    anchors.fill: parent;
                    onClicked: {
                        rfkPop.visible= true;
                    }
                }
            } */

        Rectangle{ // Blocked by rfkill popup
            id: rfkPop
            anchors.fill: parent;
            visible: false;
            color: config.bgColor;
            topLeftRadius: config.topLeftRadius;
            topRightRadius: config.topRightRadius;
            bottomLeftRadius: config.bottomLeftRadius;
            bottomRightRadius: config.bottomRightRadius;
            Text{
                id: blockedMainText
                anchors.top: parent.top;
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 5;
                color: "white";
                text: "<h1>BLUETOOTH IS <br> BLOCKED BY RFKILL! </h1>"
                font.pointSize: 13
                horizontalAlignment: Text.AlignHCenter
            }
            Text {
                id: blockedSecText
                anchors.top: blockedMainText.bottom;
                anchors.horizontalCenter: parent.horizontalCenter
                color: "white";
                text: "Disable it manually or <br> attempt to disable it:"
                font.pointSize: 16
                horizontalAlignment: Text.AlignHCenter
            }
            Rectangle{
                anchors.top: blockedSecText.bottom;
                anchors.horizontalCenter: parent.horizontalCenter;
                anchors.topMargin: 40;
                implicitHeight: 60;
                implicitWidth: 120;
                radius: 5
                color: "grey";
                Text{
                    anchors.centerIn: parent;
                    text: "<b>Unblock</b>";
                    font.pointSize: 20;
                    horizontalAlignment: Text.AlignHCenter;
                    color: "white"
                }
                MouseArea{
                    anchors.fill: parent;
                    onClicked: {
                        console.log("attempting unblocking rfkill");
                        rfkillProcess.running = true;
                    }
                }

            }
            Text {
                anchors.bottom: parent.bottom;
                anchors.horizontalCenter: parent.horizontalCenter
                color: "white";
                text: "If it fails try running: <br> <code># rfkill unblock bluetooth</code> <br> or restarting the daemon"
                font.pointSize: 15
                horizontalAlignment: Text.AlignHCenter
            }
        }

        /* Rectangle{ // Debug button, it clears the rfkill popup up
                anchors.bottom: parent.bottom;
                anchors.right: parent.right
                width: 30;
                height: 40;
                color: "green"
                MouseArea{
                    anchors.fill: parent;
                    onClicked: {
                        rfkPop.visible= false;
                    }
                }
            } */
        
    }
}