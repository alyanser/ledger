#include "firebase.h"

#include <QNetworkReply>
#include <QString>
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>
#include <QEventLoop>
#include <QtGlobal>
#include <QJsonArray>

const auto DATABASE_URL = QStringLiteral("https://firestore.googleapis.com/v1/projects/ledger-bale/databases/(default)/documents");

using namespace firebase;
using namespace firestore;

Firebase::Firebase() noexcept {
	AppOptions options;
	options.set_project_id(PROJECT_ID.data());
	options.set_api_key(API_KEY.data());
	options.set_app_id(APP_ID.data());

	app_.reset(App::Create(options));

	if(!app_) {
		qWarning() << "Failed to create Firebase app.";
		return;
	}

	db_.reset(firestore::Firestore::GetInstance(app_.get()));

	if(!db_) {
		qWarning() << "Failed to get Firestore instance.";
		return;
	}
}

void Firebase::get_bale() noexcept {

	db_->Collection("store").Document("stock").Get().OnCompletion([this](const auto & future) {

		QVariantMap response;

		if(future.error() != Error::kErrorOk) {
			response["error"] = true;

			return safe_emit([this, response]() {
				emit getBaleResponse(response);
			});
		}

		const auto * doc = future.result();
		const int bale_amount = doc->Get("baleAmount").integer_value();
		const int bale_weight = doc->Get("baleWeight").integer_value();

		response["baleAmount"] = bale_amount;
		response["baleWeight"] = bale_weight;
		response["error"] = false;

		return safe_emit([this, response]() {
			emit getBaleResponse(response);
		});

	});
}

void Firebase::set_bale(const int bale_amount, const int bale_weight) noexcept {

	auto fut = db_->Collection("store").Document("stock").Set({
		{"baleAmount", FieldValue::Integer(bale_amount)},
		{"baleWeight", FieldValue::Integer(bale_weight)}
	});

	fut.OnCompletion([this, bale_amount, bale_weight](const auto & future) {
		QVariantMap response;

		if(future.error() != Error::kErrorOk) {
			response["error"] = true;
		} else {
			response["error"] = false;
		}

		response["baleAmount"] = bale_amount;
		response["baleWeight"] = bale_weight;

		safe_emit([this, response]() {
			emit this->setBaleResponse(response);
		});
	});
}

void Firebase::add_record(const QVariantMap & data) noexcept {
	const auto date = data["date"].toString();
	const auto bale_sold = data["baleSold"].toInt();
	const auto weight_sold = data["weightSold"].toInt();
	const auto amount = data["amount"].toInt();
	const auto name = data["name"].toString();
	const auto received_amount = data["receivedAmount"].toInt();
	const auto rate = data["rate"].toFloat();
	const auto phone = data["phone"].toString();

	const auto record = MapFieldValue{
		{"date", FieldValue::String(date.toStdString())},
		{"baleSold", FieldValue::Integer(bale_sold)},
		{"weightSold", FieldValue::Integer(weight_sold)},
		{"rate", FieldValue::Double(rate)},
		{"amount", FieldValue::Integer(amount)},
		{"receivedAmount", FieldValue::Integer(received_amount)},
		{"name", FieldValue::String(name.toStdString())}
	};

	const auto normalized_name = normalize_name(data["name"].toString());

	auto daily_doc_ref = db_->Collection("daily_record").Document(normalize_date(date));
	auto daily_record_ref = daily_doc_ref.Collection("records").Document();

	const auto daily_record_id = daily_record_ref.id();

	auto users_ref = db_->Collection("users").Document(normalized_name.toStdString());
	auto user_record_ref = users_ref.Collection("records").Document(daily_record_id);

	auto bale_ref = db_->Collection("store").Document("stock");

	WriteBatch batch = db_->batch();

	const MapFieldValue bale_data = {
		{"baleAmount", FieldValue::Increment(-bale_sold)},
		{"baleWeight", FieldValue::Increment(-weight_sold)}
	};

	const MapFieldValue daily_data = {
		{"totalBaleSold", FieldValue::Increment(bale_sold)},
		{"totalWeightSold", FieldValue::Increment(weight_sold)},
		{"totalAmount", FieldValue::Increment(amount)},
		{"totalReceivedAmount", FieldValue::Increment(received_amount)},
	};

	const MapFieldValue user_data = {
		{"name", FieldValue::String(name.toStdString())},
		{"phone", FieldValue::String(phone.toStdString())},
		{"totalBaleSold", FieldValue::Increment(bale_sold)},
		{"totalWeightSold", FieldValue::Increment(weight_sold)},
		{"totalAmount", FieldValue::Increment(amount)},
		{"totalReceivedAmount", FieldValue::Increment(received_amount)},
		{"debt", FieldValue::Increment(amount - received_amount)},
	};

	batch.Set(daily_doc_ref, daily_data, SetOptions::Merge());
	batch.Set(daily_record_ref, record);
	batch.Set(users_ref, user_data, SetOptions::Merge());
	batch.Set(user_record_ref, record);
	batch.Set(bale_ref, bale_data, SetOptions::Merge());

	auto fut = batch.Commit();

	fut.OnCompletion([this, data, daily_record_id](const auto & future) {
		QVariantMap response = data;

		if(future.error() != Error::kErrorOk) {
			response["error"] = true;
		} else {
			response["error"] = false;
			response["docID"] = QString::fromStdString(daily_record_id);
		}

		safe_emit([this, response]() {
			emit this->addRecordResponse(response);
		});
	});
}

void Firebase::get_daily_records(const QString & date) noexcept {
	auto doc_ref = db_->Collection("daily_record").Document(normalize_date(date));
	auto doc_fut = doc_ref.Get();

	doc_fut.OnCompletion([this, doc_ref](const auto & future) {
		QVariantMap response;

		if(future.error() != Error::kErrorOk) {
			response["error"] = true;

			return safe_emit([this, response]() {
				emit getDailyRecordsResponseMetadata(response);
			});
		}

		const auto * doc = future.result();

		if(!doc || !doc->exists()) {
			response["empty"] = true;

			return safe_emit([this, response]() {
				emit getDailyRecordsResponseMetadata(response);
			});
		}

		response["empty"] = false;
		response["totalBaleSold"] = static_cast<int>(doc->Get("totalBaleSold").integer_value());
		response["totalWeightSold"] = static_cast<int>(doc->Get("totalWeightSold").integer_value());
		response["totalAmount"] = static_cast<int>(doc->Get("totalAmount").integer_value());
		response["totalReceivedAmount"] = static_cast<int>(doc->Get("totalReceivedAmount").integer_value());

		safe_emit([this, response]() {
			emit getDailyRecordsResponseMetadata(response);
		});

		auto records_ref = doc_ref.Collection("records");
		auto records_fut = records_ref.Get();

		records_fut.OnCompletion([this](const auto & future) {
			QVariantMap response;

			if(future.error() != Error::kErrorOk) {
				response["error"] = true;
				response["message"] = QString::fromStdString(future.error_message());

				return safe_emit([this, response]() {
					emit getDailyRecordsResponse(response);
				});
			}

			const auto * docs = future.result();

			if(!docs || docs->documents().empty()) {
				response["empty"] = true;

				return safe_emit([this, response]() {
					emit getDailyRecordsResponse(response);
				});
			}

			response["empty"] = false;

			QJsonArray records_array;

			for(const auto & doc : docs->documents()) {

				if(!doc.exists()) {
					continue;
				}

				QJsonObject record_obj;

				record_obj["docID"] = QString::fromStdString(doc.id());
				record_obj["date"] = QString::fromStdString(doc.Get("date").string_value());
				record_obj["baleSold"] = static_cast<int>(doc.Get("baleSold").integer_value());
				record_obj["weightSold"] = static_cast<int>(doc.Get("weightSold").integer_value());
				record_obj["rate"] = static_cast<float>(doc.Get("rate").double_value());
				record_obj["amount"] = static_cast<int>(doc.Get("amount").integer_value());
				record_obj["receivedAmount"] = static_cast<int>(doc.Get("receivedAmount").integer_value());
				record_obj["name"] = QString::fromStdString(doc.Get("name").string_value());
				records_array.append(record_obj);
			}

			response["records"] = records_array;
			response["error"] = false;

			safe_emit([this, response]() {
				emit getDailyRecordsResponse(response);
			});
		});
	});

}

void Firebase::get_user_records(const QString & name) noexcept {
	const auto normalized_name = normalize_name(name);

	auto user_doc_ref = db_->Collection("users").Document(normalized_name.toStdString());
	auto user_doc_fut = user_doc_ref.Get();

	user_doc_fut.OnCompletion([this, user_doc_ref](const auto & future) {
		QVariantMap response;

		if(future.error() != Error::kErrorOk) {
			response["error"] = true;

			return safe_emit([this, response]() {
				emit getUserRecordsResponseMetadata(response);
			});
		}

		const auto * doc = future.result();

		if(!doc || !doc->exists()) {
			response["empty"] = true;

			return safe_emit([this, response]() {
				emit getUserRecordsResponseMetadata(response);
			});
		}

		response["name"] = QString::fromStdString(doc->Get("name").string_value());
		response["phone"] = QString::fromStdString(doc->Get("phone").string_value());
		response["totalBaleSold"] = static_cast<int>(doc->Get("totalBaleSold").integer_value());
		response["totalWeightSold"] = static_cast<int>(doc->Get("totalWeightSold").integer_value());
		response["totalAmount"] = static_cast<int>(doc->Get("totalAmount").integer_value());
		response["totalReceivedAmount"] = static_cast<int>(doc->Get("totalReceivedAmount").integer_value());
		response["debt"] = static_cast<int>(doc->Get("debt").integer_value());

		safe_emit([this, response]() {
			emit getUserRecordsResponseMetadata(response);
		});

		auto user_records_ref = user_doc_ref.Collection("records");
		auto user_records_fut = user_records_ref.Get();

		user_records_fut.OnCompletion([this](const auto & future) {
			QVariantMap response;

			if(future.error() != Error::kErrorOk) {

				response["error"] = true;
				return safe_emit([this, response]() {
					emit getUserRecordsResponse(response);
				});
			}

			const auto * docs = future.result();

			if(!docs || docs->documents().empty()) {
				response["empty"] = true;

				return safe_emit([this, response]() {
					emit getUserRecordsResponse(response);
				});
			}

			response["empty"] = false;

			QList<QJsonValue> records_array;

			for(const auto & doc : docs->documents()) {

				if(!doc.exists()) {
					continue;
				}

				QJsonObject record_obj;

				record_obj["docID"] = QString::fromStdString(doc.id());
				record_obj["date"] = QString::fromStdString(doc.Get("date").string_value());
				record_obj["baleSold"] = static_cast<int>(doc.Get("baleSold").integer_value());
				record_obj["weightSold"] = static_cast<int>(doc.Get("weightSold").integer_value());
				record_obj["rate"] = static_cast<float>(doc.Get("rate").double_value());
				record_obj["amount"] = static_cast<int>(doc.Get("amount").integer_value());
				record_obj["receivedAmount"] = static_cast<int>(doc.Get("receivedAmount").integer_value());
				record_obj["name"] = QString::fromStdString(doc.Get("name").string_value());

				records_array.append(record_obj);
			}

			std::sort(records_array.begin(), records_array.end(), [](QJsonValue & a, QJsonValue & b) {
				return a.toObject()["date"].toString() > b.toObject()["date"].toString();
			});
			
			QJsonArray sorted_array;

			for(const auto & v : records_array) {
				sorted_array.append(v);
			}

			response["records"] = sorted_array;
			response["error"] = false;

			return safe_emit([this, response]() {
				emit getUserRecordsResponse(response);
			});
		});
	});
}

void Firebase::delete_record(const QVariantMap & data) noexcept {
	const auto doc_id = data["docID"].toString();
	const auto date = data["date"].toString();

	const auto bale_sold = data["baleSold"].toInt();
	const auto weight_sold = data["weightSold"].toInt();
	const auto amount = data["amount"].toInt();
	const auto name = normalize_name(data["name"].toString());
	const auto received_amount = data["receivedAmount"].toInt();

	const auto normalized_name = normalize_name(name);

	auto daily_doc_ref = db_->Collection("daily_record").Document(normalize_date(date));
	auto daily_record_ref = daily_doc_ref.Collection("records").Document(doc_id.toStdString());

	auto users_ref = db_->Collection("users").Document(normalized_name.toStdString());
	auto user_record_ref = users_ref.Collection("records").Document(doc_id.toStdString());

	auto bale_ref = db_->Collection("store").Document("stock");

	WriteBatch batch = db_->batch();

	const MapFieldValue bale_data = {
		{"baleAmount", FieldValue::Increment(bale_sold)},
		{"baleWeight", FieldValue::Increment(weight_sold)}
	};

	const MapFieldValue daily_data = {
		{"totalBaleSold", FieldValue::Increment(-bale_sold)},
		{"totalWeightSold", FieldValue::Increment(-weight_sold)},
		{"totalAmount", FieldValue::Increment(-amount)},
		{"totalReceivedAmount", FieldValue::Increment(-received_amount)}
	};

	const MapFieldValue user_data = {
		{"totalBaleSold", FieldValue::Increment(-bale_sold)},
		{"totalWeightSold", FieldValue::Increment(-weight_sold)},
		{"totalAmount", FieldValue::Increment(-amount)},
		{"totalReceivedAmount", FieldValue::Increment(-received_amount)},
		{"debt", FieldValue::Increment(-(amount - received_amount))}
	};

	batch.Delete(daily_record_ref);

	batch.Set(daily_doc_ref, daily_data, SetOptions::Merge());
	batch.Set(users_ref, user_data, SetOptions::Merge());

	batch.Delete(user_record_ref);

	batch.Set(bale_ref, bale_data, SetOptions::Merge());

	auto fut = batch.Commit();

	fut.OnCompletion([this, data](const auto & future) {
		QVariantMap response;

		if(future.error() != Error::kErrorOk) {
			response["error"] = true;

			return safe_emit([this, response]() {
				emit deleteRecordResponse(response);
			});
		}

		response["error"] = false;

		response["totalAmountDelta"] = -data["amount"].toInt();
		response["totalReceivedAmountDelta"] = -data["receivedAmount"].toInt();
		response["totalBaleSoldDelta"] = -data["baleSold"].toInt();
		response["totalWeightSoldDelta"] = -data["weightSold"].toInt();

		response["baleAmountDelta"] = data["baleSold"].toInt();
		response["baleWeightDelta"] = data["weightSold"].toInt();
		response["docID"] = data["docID"].toString();

		safe_emit([this, response]() {
			emit deleteRecordResponse(response);
		});

		cleanup_empty_users();
	});
}

void Firebase::cleanup_empty_users() noexcept {
	auto users_fut = db_->Collection("users").Get();

	users_fut.OnCompletion([](const auto & future) {

		if(future.error() != Error::kErrorOk) {
			return;
		}

		auto users_snapshot = future.result();

		for(const auto & user_doc : users_snapshot->documents()) {
			auto user_records = user_doc.reference().Collection("records");
			auto records_future = user_records.Get();

			records_future.OnCompletion([user_ref = user_doc.reference()](const auto & records_future) mutable {

				if(records_future.error() != Error::kErrorOk) {
					return;
				}

				auto records_snapshot = records_future.result();

				if(records_snapshot->empty()) {
					user_ref.Delete();
				}
			});
		}
	});
}

void Firebase::get_users(const QString & prefix) noexcept {
	// normalize the prefix
	const auto normalized_prefix = normalize_name(prefix);

	// now search the "users" collection for documents that start with the prefix
	auto users_ref = db_->Collection("users");

	auto query = users_ref.WhereGreaterThanOrEqualTo(FieldPath::DocumentId(), FieldValue::String(normalized_prefix.toStdString()))
		.WhereLessThan(FieldPath::DocumentId(), FieldValue::String((normalized_prefix + "\uf8ff").toStdString()));

	auto users_fut = query.Get();

	users_fut.OnCompletion([this](const auto & future) {
		QVariantMap response;

		if(future.error() != Error::kErrorOk) {
			response["error"] = true;

			return safe_emit([this, response]() {
				emit getUsersResponse(response);
			});
		}

		const auto & snapshot = *future.result();

		if(snapshot.empty()) {
			response["error"] = false;
			response["empty"] = true;

			return safe_emit([this, response]() {
				emit getUsersResponse(response);
			});
		}

		QVariantList users_list;

		for(const auto & doc : snapshot.documents()) {
			QVariantMap user_data;

			user_data["name"] = QString::fromStdString(doc.Get("name").string_value());
			user_data["phone"] = QString::fromStdString(doc.Get("phone").string_value());

			users_list.append(user_data);
		}

		response["empty"] = false;
		response["error"] = false;
		response["users"] = users_list;

		safe_emit([this, response]() {
			emit getUsersResponse(response);
		});
	});
}

void Firebase::get_monthly_totals(const int month, const int year) noexcept {

	const auto start_date = [month, year] {
		// 01-MM-YYYY
		const auto date = QString::number(1).rightJustified(2, '0') + "-" +
			QString::number(month).rightJustified(2, '0') + "-" + QString::number(year);

		return normalize_date(date);
	}();

	const auto end_date = [month, year] {
		const auto num_days_in_month = QDate(year, month, 1).daysInMonth();
		// NUM_DAYS-MM-YYYY
		const auto date = QString::number(num_days_in_month).rightJustified(2, '0') + "-" +
			QString::number(month).rightJustified(2, '0') + "-" + QString::number(year);

		return normalize_date(date);
	}();

	auto daily_ref = db_->Collection("daily_record");

	auto query = daily_ref.WhereGreaterThanOrEqualTo(FieldPath::DocumentId(), FieldValue::String(start_date))
		.WhereLessThanOrEqualTo(FieldPath::DocumentId(), FieldValue::String((end_date)));

	auto fut = query.Get();

	fut.OnCompletion([this, month, year](const auto & future) {
		QVariantMap response;

		if(future.error() != Error::kErrorOk) {
			response["error"] = true;

			return safe_emit([this, response]() {
				emit getMonthlyTotalsResponse(response);
			});
		}

		const auto & snapshot = *future.result();

		int total_bale_sold = 0;
		int total_weight_sold = 0;
		int total_amount = 0;
		int total_received_amount = 0;

		for(const auto & doc : snapshot.documents()) {
			total_bale_sold += static_cast<int>(doc.Get("totalBaleSold").integer_value());
			total_weight_sold += static_cast<int>(doc.Get("totalWeightSold").integer_value());
			total_amount += static_cast<int>(doc.Get("totalAmount").integer_value());
			total_received_amount += static_cast<int>(doc.Get("totalReceivedAmount").integer_value());
		}

		response["error"] = false;
		response["month"] = month;
		response["year"] = year;

		response["totalBaleSold"] = total_bale_sold;
		response["totalWeightSold"] = total_weight_sold;
		response["totalAmount"] = total_amount;
		response["totalReceivedAmount"] = total_received_amount;

		safe_emit([this, response]() {
			emit getMonthlyTotalsResponse(response);
		});
	});
}
