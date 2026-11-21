import QtQuick
import QtCharts

Rectangle {
    id: chartRoot
    color: "#1e1e1e"
    radius: 6
    clip: true

    // Juokseva laskuri pisteille (0, 1, 2, 3...) aikaleiman sijaan
    property int pointCount: 0

    // Yhteys C++ -kontrollerin lähettämään datatapahtumaan
    Connections {
        target: machineController ? machineController : null
        ignoreUnknownSignals: true

        function onTelemetryUpdate(temp, pressure) {
            if (temp > 200.0 || temp < 0.0)
                return;

            chartRoot.pointCount++;
            // Lisätään pisteet käyttäen juoksevaa numerointia X-akselina
            tempSeries.append(chartRoot.pointCount, temp);
            pressSeries.append(chartRoot.pointCount, pressure);

            // Rullataan X-akselia reaaliajassa eteenpäin, kun pisteitä on kertynyt yli 30 kpl
            if (chartRoot.pointCount > 30) {
                xAxis.min = chartRoot.pointCount - 30;
                xAxis.max = chartRoot.pointCount;
                tempSeries.remove(0);
                pressSeries.remove(0);
            } else {
                xAxis.max = 30;
            }
        }
    }

    ChartView {
        id: chartView
        anchors.fill: parent
        anchors.margins: -5
        backgroundColor: "#1e1e1e"
        legend.visible: true
        legend.alignment: Qt.AlignTop
        legend.labelColor: "white"
        antialiasing: true

        ValueAxis {
            id: xAxis
            min: 0
            max: 30
            labelFormat: "%d"
            labelsColor: "#aaaaaa"
            gridLineColor: "#333333"
        }

        ValueAxis {
            id: yTempAxis
            min: 0
            max: 120
            titleText: langSelector.currentIndex === 0 ? "Lämpötila (°C)" :
                       langSelector.currentIndex === 2 ? "Temp (°C)" :
                       langSelector.currentIndex === 3 ? "Temp (°C)" :
                        "Temp (°C)"
            labelsColor: "#ff5555"
            gridLineColor: "#333333"
        }

        ValueAxis {
            id: yPressAxis
            min: 0
            max: 400
            titleText: langSelector.currentIndex === 0 ? "Paine (bar)" :
                       langSelector.currentIndex === 2 ? "Druck (bar)" :
                       langSelector.currentIndex === 3 ? "Tryck (bar)" :
                        "Pressure (bar)"
            labelsColor: "#fabd2f"
            gridLineColor: "#222222"
        }

        LineSeries {
            id: tempSeries
            name: langSelector.currentIndex === 0 ? "Moottorin Lämpötila" :
                  langSelector.currentIndex === 2 ? "Motor Temperatur" :
                  langSelector.currentIndex === 3 ? "Motor Temperatur" :
                  "Engine Temperature"
            axisX: xAxis
            axisY: yTempAxis
            color: "#ff5555"
            width: 2.5
        }

        LineSeries {
            id: pressSeries
            name: langSelector.currentIndex === 0 ? "Hydrauliikan Paine" :
                  langSelector.currentIndex === 2 ? "Hydraulik Druck" :
                  langSelector.currentIndex === 3 ? "Hydrauliskt Tryck" :
                  "Hydraulic Pressure"
            axisX: xAxis
            axisYRight: yPressAxis
            color: "#fabd2f"
            width: 2.5
        }
    }
}
