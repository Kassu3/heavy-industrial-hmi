#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "machinecontroller.h"
#include <QTranslator>
#include <QLocale>

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    QQmlApplicationEngine engine;

    MachineController controller(&engine);

    engine.rootContext()->setContextProperty("machineController", &controller);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []()
        { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("IndustrialDashboard", "Main");

    return app.exec();
}
