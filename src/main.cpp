#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQuickView>
#include <QDebug>
#include <QtWidgets/QListView>
#include <QQmlContext>

#include "fileprocessing.h"

int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QApplication app(argc, argv);

    app.setOrganizationName("");
    app.setOrganizationDomain("test");

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    QQmlContext *ctx = engine.rootContext();
    FileProcessing fPrc;
    ctx->setContextProperty("fileProcessing", &fPrc);
    engine.load(url);

    return app.exec();
}
