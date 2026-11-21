#ifndef MACHINECONTROLLER_H
#define MACHINECONTROLLER_H

#include <QObject>
#include <QUdpSocket>
#include <QNetworkDatagram>
#include <QString>
#include <QTranslator>
#include <QGuiApplication>
#include <QQmlEngine>

class MachineController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(int motorRpm READ motorRpm NOTIFY telemetryChanged)
    Q_PROPERTY(double engineTemperature READ engineTemperature NOTIFY telemetryChanged)
    Q_PROPERTY(double hydraulicPressure READ hydraulicPressure NOTIFY telemetryChanged)
    Q_PROPERTY(int motorLoad READ motorLoad NOTIFY telemetryChanged)
    Q_PROPERTY(double bucketAngle READ bucketAngle NOTIFY telemetryChanged)
    Q_PROPERTY(QString systemStatus READ systemStatus NOTIFY telemetryChanged)      // tila-teksti
    Q_PROPERTY(bool emergencyStop READ emergencyStop NOTIFY telemetryChanged)       // hätäseis-tila
    Q_PROPERTY(int throttle READ throttle WRITE setThrottle NOTIFY throttleChanged) // kaasu

public:
    explicit MachineController(QQmlEngine *engine, QObject *parent = nullptr);
    ~MachineController() override;

    // Getterit lukufunktiot QML:ää varten
    int motorRpm() const { return m_motorRpm; }
    double engineTemperature() const { return m_engineTemperature; }
    double hydraulicPressure() const { return m_hydraulicPressure; }
    int motorLoad() const { return m_motorLoad; }
    double bucketAngle() const { return m_bucketAngle; }
    int throttle() const { return m_throttle; }
    QString systemStatus() const { return m_systemStatus; }
    bool emergencyStop() const { return m_emergencyStop; }

    // Metodit joita QML kutsuu, painikkeet ja säätimet
    Q_INVOKABLE void sendControlCommand(double angleChange);                         // Kauhan käskyt Pythonille
    Q_INVOKABLE void toggleEmergencyStop();                                          // Hätä-seis päälle/pois
    Q_INVOKABLE void setTargetSpeed(int speedPercent) { setThrottle(speedPercent); } // kutsui tätä Nopeuden/kaasun säätö
    Q_INVOKABLE void setThrottle(int speedPercent);                                  // Kaasu
    Q_INVOKABLE void changeLanguage(const QString &langCode);

signals:
    void telemetryChanged();                            // Päivittää QML-mittarit lennosta
    void throttleChanged();                             // Päivittää dynaamisen kaasun säätimen arvon
    void telemetryUpdate(double temp, double pressure); // Data päivittyy TelemetryChart.qml -diagrammiin

private slots:
    // Datan vastaanottaja Python simulaattorilta
    void readPendingDatagrams();

private:
    // Sisäiset muuttujat ja alkuarvot dataa varten
    int m_motorRpm = 0;
    double m_engineTemperature = 0.0;
    double m_hydraulicPressure = 0.0;
    int m_motorLoad = 0;
    double m_bucketAngle = 0.0;
    int m_throttle = 0;
    QString m_systemStatus;
    bool m_emergencyStop = false;
    // UDP-verkkosoketti
    QUdpSocket *m_udpSocket = nullptr;
    QTranslator m_translator;
    QQmlEngine *m_engine = nullptr;
};

#endif // MACHINECONTROLLER_H
