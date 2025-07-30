import QtQuick
import QtQuick.Layouts
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
            property real height: 450;
            property real width: 400;
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
            property real radius: 20; // Fallback radius
            property real topLeftRadius: 20;
            property real topRightRadius: 20;
            property real bottomLeftRadius: 20;
            property real bottomRightRadius: 20;

            // Colors
                // The background of the bottom 2/3
            property string bgColor: "#2d2a30";
                // The background of the top 1/3 panel
            property string topBgColor: "#2a282b";
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
        id: customFont;
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
            radius: config.radius;
            topLeftRadius: config.topLeftRadius;
            topRightRadius: config.topRightRadius;
            bottomLeftRadius: config.bottomLeftRadius;
            bottomRightRadius: config.bottomRightRadius;

            Rectangle{ // Top 1/3 control panel
                id: topPanel;
                anchors.horizontalCenter: parent.horizontalCenter;
                anchors.top: parent.top;
                implicitWidth: parent.width;
                implicitHeight: parent.height / 3
                topLeftRadius: config.radius
                topRightRadius: config.radius
                color: config.topBgColor;
                ColumnLayout {
                    anchors.fill: parent;

                    Text{
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
                    Layout.topMargin: 10;
                    id: slateText
                    text: "<b>SLATE BLUEZ</b>"
                    font.pointSize: 20;
                    color: "grey";
                    }
                    
                    RowLayout{ // Middle line with bluez controls
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignMiddle;
                        spacing: 40
                        ToggleButton{ // adapter power button
                            buttonId: "powerToggle";
                            showIcon: true;
                            iconOffPath: "root:/icons/bluetooth_white.svg"
                            // This double way loop should be safe, but im not sure...
                            isOn: root.adapterOn;
                            onIsOnChanged: {
                                Bluetooth.defaultAdapter.enabled = isOn
                            }
                        }
                        ToggleButton{ // Discovering
                            buttonId: "powerToggle";
                            showIcon: true;
                            iconOffPath: "root:/icons/scanning_white.svg"
                            isOn: root.isScanning;
                            onIsOnChanged: {
                                Bluetooth.defaultAdapter.discovering = isOn;
                            }
                        }
                    }

                    RowLayout{
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom; 
                        Layout.bottomMargin: 10
                        Text{
                            text: "h"
                            font.pointSize: 20
                            color: "white"
                        }
                    }


                }
            }

            Rectangle{ // Debug button, it overwrites all config with the default properties
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
            }
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
            radius: config.radius;
            color: config.bgColor;
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