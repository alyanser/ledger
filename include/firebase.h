#pragma once

#include <QObject>
#include <QNetworkAccessManager>
#include <firebase/app.h>

#include <firebase/firestore.h>

class Firebase : public QObject {
	Q_OBJECT
public:
	Firebase() noexcept;

	Q_INVOKABLE void get_bale() noexcept;
	Q_INVOKABLE void set_bale(int bale_amount, int bale_weight) noexcept;

	Q_INVOKABLE void add_record(const QVariantMap & data) noexcept;
	Q_INVOKABLE void get_daily_records(const QString & date) noexcept;

	Q_INVOKABLE void get_user_records(const QString & name) noexcept;

	Q_INVOKABLE void delete_record(const QVariantMap & data) noexcept;

	Q_INVOKABLE void get_users(const QString & prefix) noexcept;
	Q_INVOKABLE void get_monthly_totals(const int month, const int year) noexcept;

signals:
	void setBaleResponse(const QVariantMap & response);
	void getBaleResponse(const QVariantMap & response);

	void addRecordResponse(const QVariantMap & response);

	void getDailyRecordsResponseMetadata(const QVariantMap & response);
	void getDailyRecordsResponse(const QVariantMap & response);

	void getUserRecordsResponseMetadata(const QVariantMap & response);
	void getUserRecordsResponse(const QVariantMap & response);

	void deleteRecordResponse(const QVariantMap & response);
	void getUsersResponse(const QVariantMap & response);

	void getMonthlyTotalsResponse(const QVariantMap & response);

private:
	QVariantMap add_record_to_users(const QVariantMap & data) noexcept;
	void cleanup_empty_users() noexcept;

	template<typename T>
	void safe_emit(T && func) {
		QMetaObject::invokeMethod(this, std::forward<T>(func));
	}

	static QString normalize_name(const QString & name) {
		return name.trimmed().toLower().replace(' ', '_');
	}

	static std::string normalize_date(const QString & date) {
		const QStringList parts = date.split('-');
		return (parts[2] + parts[1].rightJustified(2, '0') + parts[0].rightJustified(2, '0')).toStdString();
	}

	// removed for github mirror
	constexpr static std::string_view API_KEY = "";
	constexpr static std::string_view PROJECT_ID = "";
	constexpr static std::string_view APP_ID = "";

	std::unique_ptr<firebase::App> app_;
	std::unique_ptr<firebase::firestore::Firestore> db_;
};
