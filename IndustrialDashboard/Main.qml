import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

ApplicationWindow {
    id: window
    width: 1280
    height: 800
    visible: true
    title: "Heavy Industrial Control Interface v1.0"
    color: "#121212"

    // C++ kontrollerit
    // Ominaisuudet sidottuna suoraan C++ luokan Q_PROPERTY-määrittelyihin
    readonly property int rpmValue: machineController ? machineController.motorRpm : 0
    readonly property real tempValue: machineController ? machineController.engineTemperature : 0.0
    readonly property real pressValue: machineController ? machineController.hydraulicPressure : 0.0
    readonly property int loadValue: machineController ? machineController.motorLoad : 0
    readonly property int angelValue: machineController ? machineController.bucketAngle : 0
    readonly property string statusValue: machineController ? machineController.systemStatus : "INITIALIZING..."

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 12

        // --- 1. YLÄPALKKI & JÄEJESTELMÄTILA (Hälytysbanneri) ---
        Rectangle {
            height: 50
            color:  machineController.emergencyStop ? "#cc241d" : // Punainen hätä-seis
                    (machineController.engineTemperature > 98.0) ? "#cc241d" : // Punainen ylikuumeneminen
                    (machineController.hydraulicPressure > 230.0) ? "#fabd2f" : // Keltainen ylipaine
                    "#1d2021" // Tumma lepotila / OK

            Layout.fillWidth: true
            radius: 4
            Behavior on color {
                ColorAnimation {
                    duration: 250
                }
            }

            Text {
                anchors.centerIn: parent
                //text: statusValue
                color: "white"
                font.bold: true
                font.pixelSize: 16
                text: {
                    var rawStatus = machineController.systemStatus;
                    if (rawStatus === "CONNECTING..." || rawStatus === "Connecting...") {
                        if (langSelector.currentIndex === 0) return "YHDISTETÄÄN...";
                        if (langSelector.currentIndex === 2) return "VERBINDEN...";
                        if (langSelector.currentIndex === 3) return "ANSLUTER...";
                        return "CONNECTING..."
                    }
                    return qsTr(rawStatus);
                }

            }

            ComboBox {
                id: langSelector
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 130

                model: ["Suomi", "English", "Deutsch", "Svenska"]

                onActivated: function(index) {
                    if (index === 0) machineController.changeLanguage("fi");
                    if (index === 1) machineController.changeLanguage("en");
                    if (index === 2) machineController.changeLanguage("de");
                    if (index === 3) machineController.changeLanguage("sv");
                }
            }

            Button {
                text: langSelector.currentIndex === 0 ? "🛠" + " " + "ÄLYKÄS DIAGNOSTIIKKA" :
                      langSelector.currentIndex === 2 ? "🛠" + " " + "KI-DIAGNOSTIK" :
                      langSelector.currentIndex === 3 ? "🛠" + " " + "AI-DIAGNISTIK" :
                      "🛠" + " " + "AI DIAGNOSTICS"
                flat: false

                background: Rectangle {
                    color: parent.hovered ? "#3c3836" : "#282828"
                    border.color: "#fe8019"
                    radius: 4
                }

                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                // Avaa oletusselaimen suoraan Streamlitin AI-osoitteeseen
                onClicked: {
                    Qt.openUrlExternally("http://localhost:8501")
                }
            }
        }

        // --- KESKIOSA JAETAAN MITTARIT JA MANUAALINEN OHJAUS ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 300
            spacing: 12

            // VASEN PUOLI YKKÖSNÄKYMÄN TELEMETRIAMITTARIT
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                RowLayout {
                    spacing: 10
                    Layout.fillWidth: true

                    // 1. MITTARI MOTOR RPM
                    Rectangle {
                        Layout.fillWidth: true
                        height: 100
                        color: "#1e1e1e"
                        radius: 6
                        Column {
                            anchors.centerIn: parent
                            spacing: 5
                            Text {
                                text: langSelector.currentIndex === 0 ? "MOOTTORIN RPM:" :
                                      langSelector.currentIndex === 2 ? "MOTORDREHZAHL:" :
                                      langSelector.currentIndex === 3 ? "MOTOR VARVTAL:" : "MOTOR RPM"
                                color: "white"
                                font.pixelSize: 13
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: rpmValue.toString()
                                color: "white"
                                font.pixelSize: 26
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    // 2. MITTARI ENGINE TEMP
                    Rectangle {
                        Layout.fillWidth: true
                        height: 100
                        color: "#1e1e1e"
                        radius: 6
                        Column {
                            anchors.centerIn: parent
                            spacing: 5
                            Text {
                                text: langSelector.currentIndex === 0 ? "MOOTTORIN LÄMPÖTILA:" :
                                      langSelector.currentIndex === 2 ? "MOTOR TEMP:" :
                                      langSelector.currentIndex === 3 ? "MOTOR TEMP:" :
                                      "ENGINE TEMP"
                                color: "white"
                                font.pixelSize: 13
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: qsTr("%1 °C").arg(tempValue.toFixed(1))
                                color: tempValue > 98.0 ? "#ff5555" : "white"
                                font.pixelSize: 26
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    // 3. MITTARI HYDR PRESSURE
                    Rectangle {
                        Layout.fillWidth: true
                        height: 100
                        color: "#1e1e1e"
                        radius: 6
                        Column {
                            anchors.centerIn: parent
                            spacing: 5
                            Text {
                                text: langSelector.currentIndex === 0 ? "HYDRAULIIKAN PAINE:" :
                                      langSelector.currentIndex === 2 ? "HYDR. DRUCK:" :
                                      langSelector.currentIndex === 3 ? "HYDR. TRYCK:" :
                                      "HYDR. PRESSURE:"
                                color: "white"
                                font.pixelSize: 13
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            Text {
                                text: qsTr("%1 bar").arg(pressValue.toFixed(1))
                                color: "#fabd2f"
                                font.pixelSize: 26
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }

                // MOTOR LOAD DYNAAMINEN LIUKUVÄRIPALKKI (SININEN -> KELTAINEN -> PUNAINEN)
                Rectangle {
                    Layout.fillWidth: true
                    height: 65
                    color: "#1e1e1e"
                    radius: 6
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        Text {
                            text: `${langSelector.currentIndex === 0 ? "MOOTTORIN KUORMITUS:" :
                                     langSelector.currentIndex === 2 ? "MOTORLAST:" :
                                     langSelector.currentIndex === 3 ? "MOTORBELASTNING:" :
                                     "MOTOR LOAD:"} ${loadValue}%`
                            color: "white"
                            font.bold: true
                            font.pixelSize: 12
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 15
                            color: "#333333"
                            radius: 3
                            Rectangle {
                                height: parent.height
                                width: parent.width * (loadValue / 100.0)
                                radius: 3
                                color: loadValue < 50 ? Qt.rgba(0.2, 0.6, 1.0, 1.0) :
                                        (loadValue < 80 ? Qt.rgba(1.0, 0.7, 0.0, 1.0) : Qt.rgba(1.0, 0.2, 0.2, 1.0))
                                Behavior on width {

                                    NumberAnimation {
                                        duration: 150
                                    }
                                }
                                Behavior on color {

                                    ColorAnimation {
                                        duration: 150
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // OIKEA PUOLI MANUAALISET OHJAUSTOIMINNOT & KAASU & HÄTÄSEIS
            Rectangle {
                width: 480
                color: "#1e1e1e"
                Layout.fillHeight: true
                radius: 6
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 15

                    // KAUHANOHJAUS (MANUAL CONTROL)
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            text: langSelector.currentIndex === 0 ? "MANUAALINEN OHJAUS" :
                                  langSelector.currentIndex === 2 ? "MANUELLE STEUERUNG" :
                                  langSelector.currentIndex === 3 ? "MANUELL STYRNING" :
                                  "MANUAL CONTROL"
                            color: "#fabd2f"
                            font.bold: true
                            font.pixelSize: 13
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            color: "#151515"
                            radius: 4
                            Text {
                                anchors.centerIn: parent
                                text: `${langSelector.currentIndex === 0 ? "KAUHAN KULMA:" :
                                         langSelector.currentIndex === 2 ? "LÖFFELWINKEL:" :
                                         langSelector.currentIndex === 3 ? "SKOPVINKEL:" :
                                         "BUCKET ANGLE:"} ${angelValue}°`
                                color: "white"
                                font.bold: true
                            }
                        }

                        Button {
                            id: upBtn
                            text:  langSelector.currentIndex === 0 ? "NOSTA KAUHAA (+5°)" :
                                   langSelector.currentIndex === 2 ? "LÖFFEL ANHEBEN (+5°)" :
                                   langSelector.currentIndex === 3 ? "LYFT SKOPA (+5°)" :
                                   "RAISE BUCKET (+5°)"
                            Layout.fillWidth: true
                            contentItem: Text {
                                text: upBtn.text
                                color: "white"
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                            }
                            background: Rectangle {
                                radius: 4
                                color: "#333333"
                                border.color: "#fabd2f"
                            }
                            onClicked: machineController.sendControlCommand(5.0) // Kutsuu C++ slotia
                        }
                        Button {
                            id: downBtn
                            text:  langSelector.currentIndex === 0 ? "LASKE KAUHAA (-5°)" :
                                   langSelector.currentIndex === 2 ? "LÖFFEL SENKEN (-5°)" :
                                   langSelector.currentIndex === 3 ? "SÄNK SKOPA (-5°)" :
                                   "LOWER BUCKET (-5°)"
                            Layout.fillWidth: true
                            contentItem: Text {
                                text: downBtn.text
                                color: "white"
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                            }
                            background: Rectangle {
                                radius: 4
                                color: "#333333"
                                border.color: "#fabd2f"
                            }
                            onClicked: machineController.sendControlCommand(-5.0) // Kutsuu C++ slotia
                        }
                    }

                    // KAASU & HÄTÄSEIS
                    ColumnLayout {
                        width: 180
                        spacing: 10
                        Text {
                            text: langSelector.currentIndex === 0 ? "KAASU / NOPEUS" :
                                  langSelector.currentIndex === 2 ? "DROSSEL / GESCHW" :
                                  langSelector.currentIndex === 3 ? "GASS / HASTIGHET" :
                                  "THROTTLE / SPEED"
                            color: "white"
                            font.pixelSize: 11
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Slider {
                            id: thtottleSlider
                            from: 0
                            to: 100
                            value: machineController ? machineController.throttle : 0
                            Layout.fillWidth: true
                            onMoved: machineController.setThrottle(value) // Kaksisuuntainen säätö C++:aan kun käyttäjä liikuttaa säädintä
                        }

                        Button {
                            id: estop
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            text: (langSelector.currentIndex === 0 ? "HÄTÄ-" :
                                   langSelector.currentIndex === 2 ? "NOT-" :
                                   langSelector.currentIndex === 3 ? "NÖD-" : "EMERGENCY")
                                  + "\n" +
                                  (langSelector.currentIndex === 0 ? "PYSÄYTYS" :
                                   langSelector.currentIndex === 2 ? "AUS" :
                                   langSelector.currentIndex === 3 ? "STOPP" : "STOP")
                            contentItem: Text {
                                text: estop.text
                                color: "white"
                                font.bold: true
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                textFormat: Text.PlainText
                            }

                            background: Rectangle {
                                color: "#cc241d"
                                radius: 4
                                border.color: "white"
                                border.width: 1
                            }
                            onClicked: machineController.toggleEmergencyStop()
                        }
                    }
                }
            }
        }

        // --- 3. REAALIAIKAINEN GEOMETRIA & DIAGRAMMI ---
        TelemetryChart {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 350
        }
    }
}
