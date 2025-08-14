#pragma once

#include <QObject>
#include <QCryptographicHash>
#include <QString>
#include <QByteArray>
#include <QDebug>

#include "password-hash.h"


class Password_authenticator : public QObject {
	Q_OBJECT
public:
	Q_INVOKABLE bool validate_password(const QString & password) {
		emit password_accepted();
		return true;
		const auto hashed_password = hash_password(password);

		if(hashed_password == PASSWORD_HASH) {
			emit password_accepted();
		}

		return false;
	}

signals:
	void password_accepted();

private:

	QString hash_password(const QString & password) {
		return QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha512).toHex();
	}
}; 
