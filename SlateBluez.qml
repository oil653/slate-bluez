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
            property real width: 350; // Should be between 300 and 400
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
            property string entryColor: "#686868"
                // Font color
            property string fontColor: "grey"

            // misc
                // You can set if what icon theme you want. For example 16x16 or 64x64. Bigger ones are usually more colorful
            property string iconType: "64x64";
                //  If set to true a white background will be displayed behind the icon. Useful is the icon color is the same as the entryColor
            property bool iconBackground: true;
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
                            text: "<b>SLATE BLUEZ</b>";
                            font.pointSize: 28;
                            color: "grey";
                            font.family: icelandFont.name;
                            visible: (config.width >= 350);
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
                            Rectangle {
                                id: deviceEntry;
                                property var device: modelData;
                                // Trying to keep the entry height good enough in different widths
                                height: (config.width >= 350) ? config.width / 5.3 : config.width / 5;
                                width: bottomPanel.width;
                                color: config.entryColor;
                                RowLayout{
                                    anchors.fill: parent;
                                    anchors.leftMargin: 5
                                    spacing: 8
                                    Item{ // Device icon with the background, if there is no icon its not visible
                                        implicitHeight: (config.width >= 350) ? deviceEntry.height-5 : deviceEntry.height - 20;
                                        implicitWidth: (config.width >= 350) ? deviceEntry.height-5 : deviceEntry.height - 20;
                                        Layout.alignment: Qt.AlignVCenter
                                        visible: (deviceEntry.device.icon != "");
                                        Rectangle{ 
                                            id: entryIconBackground;
                                            anchors.fill: parent;
                                            radius: 50;
                                            color: "#ffffff";
                                            opacity: 0.6; 
                                            visible: config.iconBackground;
                                        }
                                        IconImage{
                                            id: entryIcon;
                                            implicitSize: parent.height / 1.3;
                                            anchors.centerIn: entryIconBackground;
                                            source: `root:/icons/device_icons/${config.iconType}/${(deviceEntry.device.icon != "") ? deviceEntry.device.icon : "unknown" }`;
                                        }
                                    }
                                    ColumnLayout{
                                        id: entryInfo;
                                        height: deviceEntry.height;
                                        spacing: 0;
                                        Text{
                                            text: `<b>${deviceEntry.device.name}</b>`; // Device name
                                            font.pointSize: config.width / 25;
                                            color: config.fontColor;
                                        }
                                        Text{
                                            text: `<i>${deviceEntry.device.address}</i>`; // device mac
                                            font.pointSize: config.width  / 35;
                                            color: config.fontColor;
                                        }
                                        Item{ // Placeholder
                                            Layout.fillHeight: true;
                                        }
                                        Row{
                                            id: entryIcons;
                                            IconImage{ // Tick, blocked, non of these
                                                source: deviceEntry.device.trusted ? "root:/icons/trusted.svg" : (deviceEntry.device.blocked) ? "root:/icons/blocked.svg" : "";
                                                implicitSize: config.width / 15;
                                                visible: (!deviceEntry.device.trused || !deviceEntry.device.blocked) ? true : false;
                                            }
                                            IconImage{ // Displayed if the device is connected or paired
                                                source: deviceEntry.device.connected ? "root:/icons/connected.svg" : "";
                                                implicitSize: config.width / 16.6;
                                            }
                                            IconImage{ // Displayed if battery for device is available
                                                source: deviceEntry.device.batteryAvailable ? "root:/icons/battery.svg" : "";
                                                implicitSize: config.width / 16.6;
                                            }
                                            Text{ // Displayed if battery available
                                                text: (deviceEntry.device.batteryAvailable) ? `<b>${deviceEntry.device.battery * 100}%</b>` : "";
                                                font.pointSize: config.width / 25;
                                                // font.family: icelandFont.name;
                                            }
                                        }
                                    }
                                    Item{
                                        Layout.fillWidth: true;
                                    }
                                    IconImage{ // Connect button
                                        source: (!deviceEntry.device.paired || !deviceEntry.device.connected) ? "root:/icons/link.png" : (deviceEntry.device.pairing) ? "root:/icons/loading.svg" :"root:/icons/link_break.png";
                                        implicitSize: deviceEntry.height - 20;
                                        Layout.alignment: Qt.AlignVCenter;
                                        Layout.rightMargin: 10;
                                        MouseArea{ // Currently authenticated connection is not available.
                                            id: connectButton;
                                            anchors.fill: parent;
                                            onClicked: {
                                                if (!deviceEntry.device.paired){
                                                    deviceEntry.device.pair();
                                                }
                                                if (!deviceEntry.device.connected){
                                                    deviceEntry.device.connect();
                                                }
                                                if (deviceEntry.device.connected){
                                                    deviceEntry.device.disconnect();
                                                }
                                            }
                                        }
                                    }
                                }
                                //a
                                /* MouseArea {  
                                    anchors.fill: parent  
                                    acceptedButtons: Qt.RightButton  
                                    
                                    onClicked: function(mouse) {  
                                        if (mouse.button === Qt.RightButton) {  
                                            contextDropdown.visible = true  
                                            contextDropdown.x = mouse.x  
                                            contextDropdown.y = mouse.y  
                                        }  
                                    }  
                                    
                                    onPressed: function(mouse) {  
                                        if (mouse.button !== Qt.RightButton) {  
                                            mouse.accepted = false  
                                        }  
                                    }  
                                }  
                                
                                Rectangle {  
                                    id: contextDropdown  
                                    visible: false  
                                    width: 200; 
                                    height: 60
                                    color: "white";
                                    border.color: "gray"
                                    radius: 10  
                                    
                                    Column {  
                                        width: parent.width  
                                        
                                        Rectangle {  
                                            width: parent.width  
                                            height: 30  
                                            color: mouseArea1.containsMouse ? "lightgray" : "transparent";
                                            radius: 10
                                            
                                            Text {  
                                                anchors.centerIn: parent  
                                                text: "Option 1"  
                                            }  
                                            
                                            MouseArea {  
                                                id: mouseArea1  
                                                anchors.fill: parent  
                                                hoverEnabled: true  
                                                onClicked: {  
                                                    console.log("Option 1 selected")  
                                                    contextDropdown.visible = false  
                                                }  
                                            }  
                                        }  
                                        
                                        Rectangle {  
                                            width: parent.width  
                                            height: 30  
                                            color: mouseArea2.containsMouse ? "lightgray" : "transparent"  
                                            
                                            Text {  
                                                anchors.centerIn: parent  
                                                text: "Option 2"  
                                            }  
                                            
                                            MouseArea {  
                                                id: mouseArea2  
                                                anchors.fill: parent  
                                                hoverEnabled: true  
                                                onClicked: {  
                                                    console.log("Option 2 selected")  
                                                    contextDropdown.visible = false  
                                                }  
                                            }  
                                        }  
                                    }  
                                } */
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