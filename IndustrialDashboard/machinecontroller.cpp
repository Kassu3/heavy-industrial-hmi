#include "machinecontroller.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>
#include <QQmlApplicationEngine>
#include <QCoreApplication>
#include <QQmlEngine>
#include <QQmlContext>
#include <QDirIterator>

// KONSTRUKTORI
MachineController::MachineController(QQmlEngine *engine, QObject *parent)
    : QObject{parent}, m_engine{engine}
{
    m_systemStatus = tr("CONNECTING...");

    // Luodaan uusi UDP-soketti
    m_udpSocket = new QUdpSocket(this);

    // Laitetaan soketti kuuntelemaan paikallista porttia 45454
    m_udpSocket->bind(QHostAddress::LocalHost, 45454);
    // m_udpSocket->bind(QHostAddress::AnyIPv4, 45454); // Käytetään tätä, jos Python lähettää dataa Broadcastina 255.255.255,255

    // Yhdistetään soketin signaali lukufunktioon.
    // Aina kun verkosta/Pythonilta tulee dataa, Qt ilmoittaa "readyRead", ja koodi herää!
    connect(m_udpSocket, &QUdpSocket::readyRead, this, &MachineController::readPendingDatagrams);
}

// DESTRUKTORI
MachineController::~MachineController()
{
    // QUdpSocket tuhoaa itsensä automaationa, koska this asetettu parentiksi
}

// DATAN VASTAANOTTO PYTHONILTA
void MachineController::readPendingDatagrams()
{
    while (m_udpSocket->hasPendingDatagrams()) {
        QNetworkDatagram datagram = m_udpSocket->receiveDatagram();
        QByteArray data = datagram.data();

        // Puretaan Pythonilta tullut JSON-paketti
        QJsonDocument jsonDoc = QJsonDocument::fromJson(data);
        if (!jsonDoc.isNull() && jsonDoc.isObject()) {
            QJsonObject jsonObj = jsonDoc.object();

            // Päivitetään sisäiset muuttujat JSON-datasta
            m_motorRpm = jsonObj["motorRpm"].toInt();
            m_engineTemperature = jsonObj["engineTemperature"].toDouble();
            m_hydraulicPressure = jsonObj["hydraulicPressure"].toDouble();
            m_motorLoad = jsonObj["motorLoad"].toInt();
            m_bucketAngle = jsonObj["bucketAngle"].toDouble();

            // ÄLYKÄS TILAKONE / HÄLYTYSJÄRJESTELMÄ
            if (m_emergencyStop) {
                m_systemStatus = tr("EMERGENCY STOP ACTIVE");
            } else if (m_engineTemperature > 98.0) {
                m_systemStatus = tr("OVERHEAT WARNING");
            } else if (m_hydraulicPressure > 230.0) {
                m_systemStatus = tr("HIGH PRESSURE OPERATION");
            } else {
                m_systemStatus = tr("SYSTEM OK");
            }

            // Käyttöliittymälle ilmoitetaan, että mittarien arvot muuttuivat
            emit telemetryChanged();

            // Lähetetään reaaliaikainen lämpö- ja painetieto QML Chart -kuvaajalle
            emit telemetryUpdate(m_engineTemperature, m_hydraulicPressure);
        }
    }
}

// QML-Kutsu Lähetetään kaasukäsky Pythonille
void MachineController::setThrottle(int speedPercent)
{
    // Jos hätäseis on aktivoitu, kaasua ei voi muuttaa
    if (m_emergencyStop)
        return;

    // Varmistetaan turvalliset rajat (0-100%)
    if (speedPercent < 0) speedPercent = 0;
    if (speedPercent > 100) speedPercent = 100;

    // Päivitetään arvo vain, jos se oikeasti muuttui
    if (m_throttle != speedPercent) {
        m_throttle = speedPercent;

        // Ilmoitetaan käyttöliittymälle, jotta Slider päivittyy ruudulla
        emit throttleChanged();

        // Lähetetään uusi kaasun asento JSON-pakettina Python-simulaattorille porttiin 45455
        QJsonObject commandObj;
        commandObj["command"] = "set_speed";
        commandObj["value"] = m_throttle;

        QJsonDocument doc(commandObj);
        m_udpSocket->writeDatagram(doc.toJson(), QHostAddress::LocalHost, 45455);
    }
}

// QML-Kutsu Lähetetään kauhakäsky Pythonille
void MachineController::sendControlCommand(double angleChange)
{
    if (m_emergencyStop)
        return;

    QJsonObject commandObj;
    commandObj["command"] = "adjust_bucket";
    commandObj["value"] = angleChange;

    QJsonDocument doc(commandObj);
    m_udpSocket->writeDatagram(doc.toJson(), QHostAddress::LocalHost, 45455);
}

// QML-Kutsu Hätä-seis painikkeen toiminta
void MachineController::toggleEmergencyStop()
{
    m_emergencyStop = !m_emergencyStop;

    if (m_emergencyStop) {
        m_systemStatus = tr("EMERGENCY STOP ACTIVE");

        // Nollataan kaasu ja muut arvot hallitusti C++ puolella turvallisuuden vuoksi
        setThrottle(0);
        m_motorRpm = 0;
        m_motorLoad = 0;

        // Lähetetään tieto hätäpysäytyksestä myös Python-simulaattorille
        QJsonObject commandObj;
        commandObj["command"] = "emergency_stop";
        QJsonDocument doc(commandObj);
        m_udpSocket->writeDatagram(doc.toJson(), QHostAddress::LocalHost, 45455);
    } else {
        m_systemStatus = tr("SYSTEM OK");
    }

    emit telemetryChanged();
}


void MachineController::changeLanguage(const QString &langCode)
{
    //QString fileName = QString("IndustrialDashboard_%1").arg(langCode);
    // Vanhan kääntäjän poistaminen sovelluksesta
    qApp->removeTranslator(&m_translator);

    // Polku CMaken RESOURCE_PREFIX "/i18n" mukaan
    // esim. ";/i18n/dashboard_en.qm"
    QString qmPath = QString(":/i18n/dashboard_%1.qm").arg(langCode);

    qDebug() << "[C++] Ladataan kielitiedostoa polusta:" << qmPath;

    // Ladataan uusi tiedosto resurssista
    if (m_translator.load(qmPath)) {
        // Uuden kääntäjän asennus sovellukseen
        qApp->installTranslator(&m_translator);
        qDebug() << "[C++] Kieli vaihdettu onnistuneesti koodiin:" << langCode;

        // Käyttöliittymälle ilmoitetaan, että mittarien arvot muuttuivat
        emit telemetryChanged();

    } else {
        qWarning() << "[C++] VIRHE: Kielitiedostoa" << qmPath << "ei löydetty resursseista!";
    }
}

