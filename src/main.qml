import QtQuick 2.0
import QtQuick.Controls 2.5
import QtQuick.Dialogs 1.0
import QtCharts 2.0

ApplicationWindow {
    id: appWindow
    width: 1024
    height: 768
    visible: true
    title: qsTr("Top Words")

    FileDialog {
        id: fileDialog
        objectName: "fileDialog"
        title: "Choose a file"
        folder: shortcuts.home
        onAccepted: {
            if (fileDialog.fileUrl == "")
                fileLoad.loadComplete()
            else {
                pieSeries.begins(fileDialog.fileUrl)
                fileProcessing.onFileChoosen(fileDialog.fileUrl)
            }
        }
        onRejected: {
            fileLoad.loadComplete()
        }
    }

    Connections {
        target: fileProcessing
        onProcessingComplete: {
            fileLoad.loadComplete()
        }
        onDataUpdating: {
            //console.log("Update data", freq, word)
            var fnd = pieSeries.find(word)
            if (fnd) {
                //console.log("Update value ", word ," from ", fnd.value, " to ", freq );
                fnd.value = freq
            } else {
                //console.log("Add new value")
                if (pieSeries.count > 14) {
                    if (pieSeries.minValue < freq) {
                        //console.log("Try to replace exiting label")
                        var min = freq
                        var f = null
                        for(var i = 0; i < pieSeries.count; i++) {
                            //console.log("Trying: ", pieSeries.at(i).label, "(", pieSeries.at(i).value, ") < ", word, "(", freq, ")" );
                            if (pieSeries.at(i).value <= min) {
                                //Replace only smallest ABC order
                                if ((pieSeries.at(i).value === min) &&
                                        (pieSeries.at(i).label < ( f ? f.label : word)))
                                    continue
                                min = pieSeries.at(i).value;
                                f = pieSeries.at(i)
                            }
                        }
                        if (f) {
                            //We found the min < freq
                            //console.log("Replace ", f.label, " with freq ", f.value, " to ", word, " with freq ", freq);
                            pieSeries.minValue = min
                            f.label = word
                            f.value = freq
                        }
                    }
                } else {
                    //console.log("Add ", word, " = ", freq)
                    pieSeries.append(word, freq)
                }
            }
        }
    }

    ChartView {
        id: chart
        property string baseName: "Top 15 words "
        title: baseName
        //width: parent.width
        //height: parent.height
        anchors.fill: parent
        theme: ChartView.ChartThemeBrownSand
        antialiasing: true
        animationOptions: ChartView.AllAnimations

        MouseArea {
            id: ma
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: loadMenu.openHere()
        }

        Menu {
            id: loadMenu
            MenuItem {
                id: fileLoad
                text: qsTr("Load file")
                onTriggered: {
                    fileLoad.enabled = false
                    fileDialog.open()
                }
                function loadComplete() {fileLoad.enabled = true }
            }
            function openHere() {
                x = ma.mouseX
                y = ma.mouseY
                open()
            }
        }

        PieSeries {
            property int minValue: 0
            id: pieSeries
            onClicked: {
                for(var i = 0; i < pieSeries.count; i++) {
                    pieSeries.at(i).exploded = false
                }

                valueText.printValue(slice.label, slice.value)
                slice.exploded = true
            }

            function begins(fname) {
                chart.title = chart.baseName + "in " + fname
                valueText.text = ""
                minValue = 0
                clear()
            }
        }

        Text {
            id : valueText
            x: chart.width / 2
            y: chart.height - valueText.font.pixelSize - 20
            function printValue(lbl, val) {
                valueText.text = lbl + " = " + val
            }
        }
    }
}
