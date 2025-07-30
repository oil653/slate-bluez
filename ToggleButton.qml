import QtQuick;
import Quickshell;
import Quickshell.Widgets;

Item{ // Fancy button
    id: root;

    // Exposed properties:

    property bool isOn; // true if the switch state is ON. Can be maniulated externally

    // Logging
    property bool enableLogging: false; // If enabled a debug message will be printed if the state is changed
    property string buttonId; // The id of the button 

    // Icon
    property bool showIcon: false; // If its true the icon will be shown
    property string iconOffPath: ""; // The icon if the switch is off
    property string iconOnPath: ""; // The icon path if the switch is on. If not specified will be the same as iconOffPath

    // Size and padding
    property real radius: 15; // The radius of the components not the actuall Item 
    width: 60; // Width of both this item and the children elements
    height: 30; // Height of both this item and the children elements

    Rectangle{
        id: buttonRoot
        width: parent.width;
        height: parent.height;
        radius: root.radius;
        color: "white";
        transitions: Transition{
            ColorAnimation{
                properties: "color"
                duration: 300 // ms
                easing.type: Easing.InOutQuad    
            }
        }
        Rectangle{
            id: toggleButton
            antialiasing: true;
            width: parent.height ;
            height: parent.height ;
            color: "#1f2120";
            radius: parent.radius;
            state: (root.isOn) ? "ON" : "OFF";
            states: [
                State{
                    name: "OFF";
                    PropertyChanges{target: toggleButton; x: 0 ; y: 0; border.color: "white"}
                    PropertyChanges{target: buttonRoot; color: "white"}
                },
                State {
                    name: "ON";
                    PropertyChanges{target: toggleButton; x: parent.width - parent.height; y: 0; border.color: "green"}
                    PropertyChanges{target: buttonRoot; color: "green"}
                }
            ]
            transitions: Transition {  
                NumberAnimation {
                    properties: "x"
                    duration: 300 //ms
                    easing.type: Easing.InOutQuad  
                    }  
                } 
            IconImage{
                id: icon
                anchors.centerIn: parent;

                // If showIcon is false it puts and empty string as source, not loading anything
                // if showIcon is true and the switch is off it puts in the iconOffPath as source
                // If showIcon is true and the switch is on it checks of iconOnPath is empty, if yes it uses the iconOffPath if 
                // NOT empty it uses the iconOnPath
                // I really hate this if syntax....
                source: {
                    root.showIcon ? 
                        (root.isOn ?
                            ((root.iconOnPath == "") ?
                                    root.iconOffPath 
                            : root.iconOnPath) 
                        : root.iconOffPath )
                    : ""
                }
                implicitSize: parent.height - 10;
            }
        }
            MouseArea{
                anchors.fill: parent;
                onClicked: {
                    root.isOn = (root.isOn) ? false : true;
                    if (root.enableLogging){
                        console.log(root.buttonId + " is now " + toggleButton.state);
                    }
                }
            }
    }
}