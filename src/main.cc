#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QQmlContext>
#include <QDebug>
#include <QResource>
#include <QEventLoop>

#include <QOpenGLContext>
#include <QSurfaceFormat>

#include "password-authenticator.h"
#include "firebase.h"

int main(int argc, char ** argv) {

#ifdef Q_OS_WIN
	qputenv("QSG_RHI_BACKEND", "opengl");
#endif

	QGuiApplication app(argc, argv);

	app.setApplicationName("Bale Ledger");
	app.setApplicationVersion("1.0.0");
	app.setApplicationDisplayName("Bale Ledger");
	app.setWindowIcon(QIcon(":/icons/baleLedgerIcon.ico"));

	// {
	// 	QQmlApplicationEngine auth_engine;
	// 	QEventLoop loop;
	// 	Password_authenticator password_auth;

	// 	QObject::connect(&password_auth, &Password_authenticator::password_accepted, &loop, &QEventLoop::quit);

	// 	auth_engine.rootContext()->setContextProperty("password_auth", &password_auth);
	// 	auth_engine.load(QUrl("qrc:/ui/PasswordDialog.qml"));
	// 	loop.exec();
	// }

	QQmlApplicationEngine engine;

	Firebase firebase;

	engine.rootContext()->setContextProperty("firebase", &firebase);

	engine.load(QUrl("qrc:/ui/mainWindow.qml"));

	if(!engine.rootObjects().isEmpty()) {
		auto * window = qobject_cast<QQuickWindow*>(engine.rootObjects().first());

		if(window) {
			window->showMaximized();
		}
	}

	return app.exec();
}
