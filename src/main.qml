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

    //Signals from file processing C++ part
    Connections {
        target: fileProcessing
        function onProcessingComplete() {
            fileLoad.loadComplete()
        }
        function onProgress(percentage) {
            fileLoad.text = qsTr("Done ") +  (percentage) + " %"
        }

        function onDataUpdating(freq, word) {
            var fnd = pieSeries.find(word)
            if (fnd) {
                //Replace an existing value
                fnd.value = freq
            } else {
                if (pieSeries.count > 14) {
                    //Try to replace an existing one
                    if (pieSeries.minValue <= freq) {
                        var min = freq
                        var f = null
                        for(var i = 0; i < pieSeries.count; i++) {
                            if (pieSeries.at(i).value <= min) {
                                //Replace only label with smallest ABC order
                                if ((pieSeries.at(i).value === min) &&
                                        (pieSeries.at(i).label < ( f ? f.label : word)))
                                    continue
                                min = pieSeries.at(i).value;
                                f = pieSeries.at(i)
                            }
                        }
                        if (f) {
                            //We found the min < freq label
                            pieSeries.minValue = min
                            f.label = word
                            f.value = freq
                        }
                    }
                } else {
                    //Just add new one
                    pieSeries.append(word, freq)
                }
            }
        }
    }

    ChartView {
        id: chart
        property string baseName: qsTr("Top 15 words ")
        title: baseName
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
                property  string openingReady : qsTr("Load file")
                text: fileLoad.openingReady
                onTriggered: {
                    fileLoad.enabled = false
                    fileDialog.open()
                }
                function loadComplete() {
                    fileLoad.text = fileLoad.openingReady
                    fileLoad.enabled = true }
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
            //Show slice value on click
            onClicked: {
                if (slice.exploded === true) {
                    slice.exploded = false
                    valueText.text = ""
                } else {
                    for(var i = 0; i < pieSeries.count; i++) {
                        pieSeries.at(i).exploded = false
                    }

                    valueText.printValue(slice.label, slice.value)
                    slice.exploded = true
                }
            }

            //Start new file
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
                valueText.text = qsTr("Word \"") + lbl + qsTr("\" occurs ") + val + qsTr(" times")
            }
        }
    }
}
