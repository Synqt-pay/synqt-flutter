// ignore_for_file: lines_longer_than_80_chars

import 'model.dart';
import 'payment_methods.dart';

/// PayinAcceptedResponse, by which field SYNQT sent.
sealed class PayinAcceptedResponse {
  const PayinAcceptedResponse();

  /// Throws [FormatException] when SYNQT sent none of `paymentMethodResponse`, `redirectTo`.
  factory PayinAcceptedResponse.fromJson(Map<String, Object?> json) {
    if (json.containsKey('paymentMethodResponse')) return PayinAcceptedMethodResponse.fromJson(json);
    if (json.containsKey('redirectTo')) return PayinAcceptedRedirectResponse.fromJson(json);
    throw const FormatException('PayinAcceptedResponse has none of paymentMethodResponse, redirectTo');
  }
}

final class AccountResponseDetail extends Object {
  const AccountResponseDetail({
    this.accountName,
    this.accountNumber,
    this.accountType,
    this.bankCode,
    this.paymentOperator,
    this.bankName,
    this.bankBranch,
    this.bankCity,
    this.bankProvince,
  });

  /// Name of the bank account. min 1, max 64, pattern `^(\p{L}\p{M}*?|[\d, ;:_'"!%=@#&\-\.\?\$\(\)\+\*\|])*$`.
  final String? accountName;

  /// Number of the bank account.
  final String? accountNumber;

  /// Type of the bank account. min 1, max 64, pattern `^(\p{L}\p{M}*?|[, ;:_'"!%=@#&\-\.\?\$\(\)\+\*\|])*$`.
  final String? accountType;

  /// Bank code of the bank. min 1.
  final String? bankCode;

  /// Payment operator code.
  final PaymentOperatorIncoming? paymentOperator;

  /// Name of the bank. min 1.
  final String? bankName;

  /// Branch name of the bank. min 1.
  final String? bankBranch;

  /// City of the bank. min 1.
  final String? bankCity;

  /// Province of the bank. min 1.
  final String? bankProvince;

  factory AccountResponseDetail.fromJson(Map<String, Object?> json) => AccountResponseDetail(
    accountName: json['accountName'] as String?,
    accountNumber: json['accountNumber'] as String?,
    accountType: json['accountType'] as String?,
    bankCode: json['bankCode'] as String?,
    paymentOperator: _obj(json['paymentOperator'], PaymentOperatorIncoming.fromJson),
    bankName: json['bankName'] as String?,
    bankBranch: json['bankBranch'] as String?,
    bankCity: json['bankCity'] as String?,
    bankProvince: json['bankProvince'] as String?,
  );
}

final class AvailablePayinOption extends Object {
  const AvailablePayinOption({this.paymentMethodCode, this.paymentOperators, this.segmentCode});

  /// Payment method is a payment instrument that your customers use (such as online bank transfers, VA payments, UPI and so on). min 1. Always present per spec.
  final String? paymentMethodCode;
  final List<PaymentOperatorIncoming>? paymentOperators;

  /// A customer segment which allows you to divide your customers into groups that reflect similarity among customers in each group. min 1.
  final String? segmentCode;

  factory AvailablePayinOption.fromJson(Map<String, Object?> json) => AvailablePayinOption(
    paymentMethodCode: json['paymentMethodCode'] as String?,
    paymentOperators: (json['paymentOperators'] as List?)
        ?.map((item) => PaymentOperatorIncoming.fromJson(item as Map<String, Object?>))
        .toList(),
    segmentCode: json['segmentCode'] as String?,
  );
}

/// The list of possible payment options. The list always contains at least one payment option.
final class AvailablePayinOptionList extends Object {
  const AvailablePayinOptionList({this.data, this.dataVariantCurrencies});

  final List<AvailablePayinOption>? data;
  final List<AvailablePayinOptionVariantCurrency>? dataVariantCurrencies;

  factory AvailablePayinOptionList.fromJson(Map<String, Object?> json) => AvailablePayinOptionList(
    data: (json['data'] as List?)?.map((item) => AvailablePayinOption.fromJson(item as Map<String, Object?>)).toList(),
    dataVariantCurrencies: (json['dataVariantCurrencies'] as List?)
        ?.map((item) => AvailablePayinOptionVariantCurrency.fromJson(item as Map<String, Object?>))
        .toList(),
  );
}

final class AvailablePayinOptionVariantCurrency extends Object {
  const AvailablePayinOptionVariantCurrency({
    this.paymentMethodCode,
    this.paymentOperators,
    this.segmentCode,
    this.money,
  });

  /// Payment method is a payment instrument that your customers use (such as online bank transfers, VA payments, UPI and so on). min 1. Always present per spec.
  final String? paymentMethodCode;
  final List<PaymentOperatorIncoming>? paymentOperators;

  /// A customer segment which allows you to divide your customers into groups that reflect similarity among customers in each group. min 1.
  final String? segmentCode;

  /// Always present per spec.
  final Money? money;

  factory AvailablePayinOptionVariantCurrency.fromJson(Map<String, Object?> json) =>
      AvailablePayinOptionVariantCurrency(
        paymentMethodCode: json['paymentMethodCode'] as String?,
        paymentOperators: (json['paymentOperators'] as List?)
            ?.map((item) => PaymentOperatorIncoming.fromJson(item as Map<String, Object?>))
            .toList(),
        segmentCode: json['segmentCode'] as String?,
        money: _obj(json['money'], Money.fromJson),
      );
}

/// Customer related to this payment.
final class CustomerDetail extends Object {
  const CustomerDetail({this.idCustomer});

  /// The ID of customer given by merchant. min 1, max 250.
  final String? idCustomer;

  factory CustomerDetail.fromJson(Map<String, Object?> json) =>
      CustomerDetail(idCustomer: json['idCustomer'] as String?);
}

/// TODO: Add description
final class ExternalProvider extends Object {
  const ExternalProvider({this.code, this.name});

  /// min 1, max 128. Always present per spec.
  final String? code;

  /// min 1. Always present per spec.
  final String? name;

  factory ExternalProvider.fromJson(Map<String, Object?> json) =>
      ExternalProvider(code: json['code'] as String?, name: json['name'] as String?);
}

final class ExternalProviders extends Object {
  const ExternalProviders({this.providers});

  final List<ExternalProvider>? providers;

  factory ExternalProviders.fromJson(Map<String, Object?> json) => ExternalProviders(
    providers: (json['providers'] as List?)
        ?.map((item) => ExternalProvider.fromJson(item as Map<String, Object?>))
        .toList(),
  );
}

final class FailureReasons extends Object {
  const FailureReasons({this.failedAt, this.failureReasonCode, this.message});

  /// Date and time of the payment failure. date-time. Always present per spec.
  final String? failedAt;

  /// * `SYSTEM` - Internal error. one of SYSTEM, PAYMENT_PROCESS_ERROR, ENTITY_EXPIRED, DIFFERENT_AMOUNT_CONFIRMED, CURRENCY_NOT_SUPPORTED, CURRENCY_PRECISION_EXCEEDED, PAYMENT_METHOD_NOT_FOUND, PAYMENT_METHOD_ERROR, PAYMENT_OPERATOR_NOT_FOUND, PAYMENT_OPERATOR_INVALID, PAYMENT_OPERATOR_UNAVAILABLE, PAYMENT_CHANNEL_NO_ACTIVE_FOUND, PAYMENT_CHANNEL_NO_OPENED_FOUND, PAYMENT_CHANNEL_NO_SEGMENT_FOUND, PAYMENT_CHANNEL_AMOUNT_LIMITS, PAYMENT_CHANNEL_DAILY_LIMITS, IP_DENIED, BALANCE_INSUFFICIENT, INVALID_ACCOUNT_NUMBER, INVALID_ACCOUNT_NAME, INVALID_PHONE_NUMBER, INVALID_ID_NUMBER, INCORRECT_CURRENCY, CUSTOMER_VERIFICATION_REJECTED, CUSTOMER_VERIFICATION_FAILED, ACCOUNT_TYPE_INELIGIBLE, NAME_SIMILARITY_CHECK_FAILED, INVALID_IFSC, FEATURE_UNAVAILABLE, CUSTOMER_ACCOUNT_LIMIT_EXCEEDED, CUSTOMER_VERIFICATION_INACTIVITY, CUSTOMER_NOT_REGISTERED, SECURITY_CHECK_FAILED, VOUCHER_INELIGIBLE. Always present per spec.
  final String? failureReasonCode;

  /// Additional description of the failure reason.
  final String? message;

  factory FailureReasons.fromJson(Map<String, Object?> json) => FailureReasons(
    failedAt: json['failedAt'] as String?,
    failureReasonCode: json['failureReasonCode'] as String?,
    message: json['message'] as String?,
  );
}

final class Money extends Object {
  const Money({this.amount, this.currencyCode});

  /// Amount is accepted in the smallest currency unit. Always present per spec.
  final num? amount;

  /// For supported currencies please refer to `GET /currencies`. min 1. Always present per spec.
  final String? currencyCode;

  factory Money.fromJson(Map<String, Object?> json) =>
      Money(amount: json['amount'] as num?, currencyCode: json['currencyCode'] as String?);
}

/// Fees charged for this payment.
final class MoneyFee extends Object {
  const MoneyFee({this.amount, this.currencyCode});

  /// Amount is accepted in the smallest currency unit. Always present per spec.
  final num? amount;

  /// For supported currencies please refer to `GET /currencies`. min 1. Always present per spec.
  final String? currencyCode;

  factory MoneyFee.fromJson(Map<String, Object?> json) =>
      MoneyFee(amount: json['amount'] as num?, currencyCode: json['currencyCode'] as String?);
}

final class MoneyPaymentRequested extends SynqtModel {
  const MoneyPaymentRequested({required this.amount, required this.currencyCode});

  /// Requested payment amount.
  final num amount;

  /// For supported currencies please refer to `GET /currencies`. min 1.
  final String currencyCode;

  @override
  Map<String, Object?> toJson() => {'amount': amount, 'currencyCode': currencyCode};

  factory MoneyPaymentRequested.fromJson(Map<String, Object?> json) =>
      MoneyPaymentRequested(amount: json['amount'] as num, currencyCode: json['currencyCode'] as String);
}

/// For every payment method there is appropriate payment specific request object in `paymentMethod` attribute. If you have used the `POST /payins/!availablePaymentOptions` API to get the list of the available payment options, then it is expected that you use the same input data here to make sure that the payment will be accepted.
final class Payin extends SynqtModel {
  const Payin({
    required this.paymentRequested,
    required this.paymentMethod,
    required this.returnUrl,
    this.callbackUrl,
    this.customerIp,
  });

  /// The requested payment.
  final PaymentRequested paymentRequested;

  /// Payment method is a payment instrument that your customers use (such as online bank transfers, VA payments, UPI and so on).
  final PaymentMethodPayin paymentMethod;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000.
  final String returnUrl;

  /// This is the URL where the system will send the transaction final status after payment has been completed. max 1000.
  final String? callbackUrl;

  /// The IP address of the customer making the payment in either the IPv4 or IPv6 format.
  final String? customerIp;

  @override
  Map<String, Object?> toJson() => {
    'paymentRequested': paymentRequested.toJson(),
    'paymentMethod': paymentMethod.toJson(),
    'returnUrl': returnUrl,
    if (callbackUrl != null) 'callbackUrl': callbackUrl,
    if (customerIp != null) 'customerIp': customerIp,
  };
}

/// For every payment method there is appropriate payment specific response object in `paymentMethodResponse` attribute. Use data from `paymentMethodResponse` for payment completion (for example show to the customer).
final class PayinAcceptedMethodResponse extends PayinAcceptedResponse {
  const PayinAcceptedMethodResponse({this.paymentRequested, this.paymentMethodResponse});

  /// The requested payment. Always present per spec.
  final PaymentRequested? paymentRequested;

  /// Always present per spec.
  final PaymentMethodResponsePayin? paymentMethodResponse;

  factory PayinAcceptedMethodResponse.fromJson(Map<String, Object?> json) => PayinAcceptedMethodResponse(
    paymentRequested: _obj(json['paymentRequested'], PaymentRequested.fromJson),
    paymentMethodResponse: _obj(json['paymentMethodResponse'], PaymentMethodResponsePayin.fromJson),
  );
}

/// Customer should be redirected to specified URL for the next payment process step.
final class PayinAcceptedRedirectResponse extends PayinAcceptedResponse {
  const PayinAcceptedRedirectResponse({this.paymentRequested, this.redirectTo});

  /// The requested payment. Always present per spec.
  final PaymentRequested? paymentRequested;

  /// Always present per spec.
  final Redirection? redirectTo;

  factory PayinAcceptedRedirectResponse.fromJson(Map<String, Object?> json) => PayinAcceptedRedirectResponse(
    paymentRequested: _obj(json['paymentRequested'], PaymentRequested.fromJson),
    redirectTo: _obj(json['redirectTo'], Redirection.fromJson),
  );
}

final class PayinDetail extends Object {
  const PayinDetail({
    this.paymentRequested,
    this.process,
    this.fee,
    this.paymentMethodResponse,
    this.settlement,
    this.customer,
  });

  /// The requested payment. Always present per spec.
  final PaymentRequested? paymentRequested;

  /// Always present per spec.
  final PaymentProcess? process;

  /// Fees charged for this payment. Always present per spec.
  final MoneyFee? fee;

  /// Always present per spec.
  final PaymentMethodResponsePayin? paymentMethodResponse;

  /// Payment method is a payment instrument that your customers use (such as online bank transfers, VA payments, UPI and so on).
  final SettlementMethod? settlement;

  /// Customer related to this payment.
  final CustomerDetail? customer;

  factory PayinDetail.fromJson(Map<String, Object?> json) => PayinDetail(
    paymentRequested: _obj(json['paymentRequested'], PaymentRequested.fromJson),
    process: _obj(json['process'], PaymentProcess.fromJson),
    fee: _obj(json['fee'], MoneyFee.fromJson),
    paymentMethodResponse: _obj(json['paymentMethodResponse'], PaymentMethodResponsePayin.fromJson),
    settlement: _obj(json['settlement'], SettlementMethod.fromJson),
    customer: _obj(json['customer'], CustomerDetail.fromJson),
  );
}

final class PaymentAccountDetail extends Object {
  const PaymentAccountDetail({this.customerAccountRequest, this.customerAccountProcess});

  /// Details of customer's account collected in payment request. Always present per spec.
  final AccountResponseDetail? customerAccountRequest;

  /// Details of customer's account collected during payment process. Always present per spec.
  final AccountResponseDetail? customerAccountProcess;

  factory PaymentAccountDetail.fromJson(Map<String, Object?> json) => PaymentAccountDetail(
    customerAccountRequest: _obj(json['customerAccountRequest'], AccountResponseDetail.fromJson),
    customerAccountProcess: _obj(json['customerAccountProcess'], AccountResponseDetail.fromJson),
  );
}

final class PaymentOperatorIncoming extends Object {
  const PaymentOperatorIncoming({this.code, this.name, this.externalProviders});

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? code;

  /// min 1, max 1000. Always present per spec.
  final String? name;
  final ExternalProviders? externalProviders;

  factory PaymentOperatorIncoming.fromJson(Map<String, Object?> json) => PaymentOperatorIncoming(
    code: json['code'] as String?,
    name: json['name'] as String?,
    externalProviders: _obj(json['externalProviders'], ExternalProviders.fromJson),
  );
}

final class PaymentProcess extends Object {
  const PaymentProcess({
    this.status,
    this.failureReasons,
    this.createdAt,
    this.processedAt,
    this.isTest,
    this.processorStatus,
  });

  /// * `PROCESSING` - payment process is not finished yet. one of PROCESSING, SUCCESS, FAILED, REFUSED. Always present per spec.
  final String? status;
  final FailureReasons? failureReasons;

  /// Date and time when payment was accepted by platform. date-time. Always present per spec.
  final String? createdAt;

  /// Date and time when payment was processed by platform. date-time.
  final String? processedAt;

  /// This flag is set to `true` when payment was done with testing merchant or testing channel. Always present per spec.
  final bool? isTest;

  /// If present, this field specifies the status of the payment processing by an external processor. one of ACCEPTED, PROCESSED.
  final String? processorStatus;

  factory PaymentProcess.fromJson(Map<String, Object?> json) => PaymentProcess(
    status: json['status'] as String?,
    failureReasons: _obj(json['failureReasons'], FailureReasons.fromJson),
    createdAt: json['createdAt'] as String?,
    processedAt: json['processedAt'] as String?,
    isTest: json['isTest'] as bool?,
    processorStatus: json['processorStatus'] as String?,
  );
}

/// The requested payment.
final class PaymentRequested extends SynqtModel {
  const PaymentRequested({required this.money, this.segmentCode, this.exchangedToCurrency});

  final MoneyPaymentRequested money;

  /// A customer segment which allows you to divide your customers into groups that reflect similarity among customers in each group. min 1.
  final String? segmentCode;

  /// For supported currencies please refer to `GET /currencies`. min 1.
  final String? exchangedToCurrency;

  @override
  Map<String, Object?> toJson() => {
    'money': money.toJson(),
    if (segmentCode != null) 'segmentCode': segmentCode,
    if (exchangedToCurrency != null) 'exchangedToCurrency': exchangedToCurrency,
  };

  factory PaymentRequested.fromJson(Map<String, Object?> json) => PaymentRequested(
    money: MoneyPaymentRequested.fromJson(json['money'] as Map<String, Object?>),
    segmentCode: json['segmentCode'] as String?,
    exchangedToCurrency: json['exchangedToCurrency'] as String?,
  );
}

final class Redirection extends Object {
  const Redirection({this.method, this.url, this.data});

  /// The HTTP method that should be used for redirection. one of GET, POST. Always present per spec.
  final String? method;

  /// The destination URL for redirect to. Always present per spec.
  final String? url;

  /// The optional data in JSON format - a key-value pairs that must be used for redirection when POST method is used.
  final String? data;

  factory Redirection.fromJson(Map<String, Object?> json) =>
      Redirection(method: json['method'] as String?, url: json['url'] as String?, data: json['data'] as String?);
}

T? _obj<T>(Object? value, T Function(Map<String, Object?>) read) =>
    value == null ? null : read(value as Map<String, Object?>);
