// ignore_for_file: lines_longer_than_80_chars

import 'model.dart';
import 'results.dart' show SynqtArgumentException;

/// The `paymentMethod` object of POST /payins/{idPayin}, one subclass per method. Field rules differ per method and
/// sometimes per currency.
sealed class PaymentMethod extends SynqtModel {
  const PaymentMethod();

  /// The method's code in the API, such as CAPITEC_PAY.
  String get paymentMethodCode;
}

/// Absa Pay offers a simple, quick and secure way to make payments without needing to input banking login details. Customers can select their preferred account for payment and securely authorize the transaction through the banking app.
final class AbsaPayMethod extends PaymentMethod {
  const AbsaPayMethod({this.account, this.emailAddress, this.passportNumber, this.said, this.customerName});

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account? account;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  /// min 8, max 9, pattern `^[a-zA-Z][0-9]+$`.
  final String? passportNumber;

  /// min 13, max 13, pattern `^[0-9]*$`.
  final String? said;

  /// Customer's first, middle and last name.
  final PersonName? customerName;

  @override
  String get paymentMethodCode => 'ABSA_PAY';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'ABSA_PAY',
    if (account != null) 'account': account?.toJson(),
    if (emailAddress != null) 'emailAddress': emailAddress,
    if (passportNumber != null) 'passportNumber': passportNumber,
    if (said != null) 'said': said,
    if (customerName != null) 'customerName': customerName?.toJson(),
  };
}

/// Capitec Pay is an easy, fast and safe way to pay without having to enter the bank card details or share banking login information. The customer can choose the account he wants to pay from and authenticate the payment safely in the banking app.
final class CapitecPayMethod extends PaymentMethod {
  const CapitecPayMethod({
    this.account,
    this.emailAddress,
    this.phoneNumber,
    this.said,
    this.customerName,
    this.paymentOperatorCode,
  });

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account? account;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  /// Your customer's mobile phone number, starting with 0. min 12, max 12.
  final String? phoneNumber;

  /// min 13, max 13, pattern `^[0-9]*$`.
  final String? said;

  /// Customer's first, middle and last name.
  final PersonName? customerName;

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String? paymentOperatorCode;

  @override
  String get paymentMethodCode => 'CAPITEC_PAY';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'CAPITEC_PAY',
    if (account != null) 'account': account?.toJson(),
    if (emailAddress != null) 'emailAddress': emailAddress,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    if (said != null) 'said': said,
    if (customerName != null) 'customerName': customerName?.toJson(),
    if (paymentOperatorCode != null) 'paymentOperatorCode': paymentOperatorCode,
  };
}

/// Card payment method.
final class CardMethod extends PaymentMethod {
  const CardMethod({
    required this.card,
    this.paymentContacts,
    this.paymentOperatorCode,
    this.saveCardForFutureUse,
    this.recurring,
  });

  final CardData card;
  final CardPaymentContacts? paymentContacts;

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String? paymentOperatorCode;
  final bool? saveCardForFutureUse;
  final RecurringPayment? recurring;

  @override
  String get paymentMethodCode => 'CARD';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'CARD',
    'card': card.toJson(),
    if (paymentContacts != null) 'paymentContacts': paymentContacts?.toJson(),
    if (paymentOperatorCode != null) 'paymentOperatorCode': paymentOperatorCode,
    if (saveCardForFutureUse != null) 'saveCardForFutureUse': saveCardForFutureUse,
    if (recurring != null) 'recurring': recurring?.toJson(),
  };
}

/// Convenience Store Payments. Payment method which requires customer to copy Payment Code from the Payment application right after the payment is submitted into kiosk in convenience store during the payment on the cashier.
final class CodePaymentMethod extends PaymentMethod {
  const CodePaymentMethod({
    required this.paymentOperatorCode,
    required this.emailAddress,
    required this.phoneNumber,
    required this.paymentLocation,
    this.account,
  });

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String paymentOperatorCode;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String emailAddress;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`.
  final String phoneNumber;

  /// Specifies location where a customer is making the payment (e.g.
  final PaymentLocation paymentLocation;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account? account;

  @override
  String get paymentMethodCode => 'CODE_PAYMENT';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'CODE_PAYMENT',
    'paymentOperatorCode': paymentOperatorCode,
    'emailAddress': emailAddress,
    'phoneNumber': phoneNumber,
    'paymentLocation': paymentLocation.toJson(),
    if (account != null) 'account': account?.toJson(),
  };
}

/// Crypto Offline is a payment method that allows customers to pay by crypto currency from they crypto wallet to an address that they are provided.
final class CryptoOfflineMethod extends PaymentMethod {
  const CryptoOfflineMethod({required this.paymentOperatorCode, this.emailAddress});

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String paymentOperatorCode;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  @override
  String get paymentMethodCode => 'CRYPTO_OFFLINE';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'CRYPTO_OFFLINE',
    'paymentOperatorCode': paymentOperatorCode,
    if (emailAddress != null) 'emailAddress': emailAddress,
  };
}

/// Payment method which requires customer to scan QR code from the Payment application by Customer's Payment service application right after the payment is submitted.
final class DuitNowMethod extends PaymentMethod {
  const DuitNowMethod({required this.account, this.paymentOperatorCode, this.emailAddress});

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account account;

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String? paymentOperatorCode;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  @override
  String get paymentMethodCode => 'DUITNOW';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'DUITNOW',
    'account': account.toJson(),
    if (paymentOperatorCode != null) 'paymentOperatorCode': paymentOperatorCode,
    if (emailAddress != null) 'emailAddress': emailAddress,
  };
}

/// E-Wallet is a payment option on Indonesian market that allows customers to use major Indonesian wallets for payments. Customer is either automatically redirected to a chosen wallet with all payment details pre-populated to finalize the payment or directly receives push notification to authorize the payment in case of OVO wallet.
final class EWalletMethod extends PaymentMethod {
  const EWalletMethod({required this.paymentOperatorCode, this.account, this.emailAddress, this.phoneNumber});

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String paymentOperatorCode;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account? account;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`.
  final String? phoneNumber;

  @override
  String get paymentMethodCode => 'EWALLET';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'EWALLET',
    'paymentOperatorCode': paymentOperatorCode,
    if (account != null) 'account': account?.toJson(),
    if (emailAddress != null) 'emailAddress': emailAddress,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
  };
}

/// FNB Direct EFT is a digital payment method that enables customers to make secure payments directly through their FNB app. Rather than manually entering bank details, customers can approve the payment on their phone, creating a faster, safer, and more seamless checkout experience.
final class FnbDirectEFTMethod extends PaymentMethod {
  const FnbDirectEFTMethod({
    required this.customerName,
    required this.emailAddress,
    required this.account,
    this.passportNumber,
    this.said,
  });

  /// Customer's first and last name.
  final PersonName customerName;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String emailAddress;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account account;

  /// min 8, max 9, pattern `^[a-zA-Z][0-9]+$`.
  final String? passportNumber;

  /// min 13, max 13, pattern `^[0-9]*$`.
  final String? said;

  @override
  String get paymentMethodCode => 'FNB_DIRECT_EFT';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'FNB_DIRECT_EFT',
    'customerName': customerName.toJson(),
    'emailAddress': emailAddress,
    'account': account.toJson(),
    if (passportNumber != null) 'passportNumber': passportNumber,
    if (said != null) 'said': said,
  };
}

/// FPX (Financial Process Exchange) is a real-time online payment system in Malaysia that enables secure, instant payments by redirecting users to their selected FPX-participating banks.
final class FpxMethod extends PaymentMethod {
  const FpxMethod({required this.account, required this.paymentOperatorCode, this.emailAddress});

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account account;

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String paymentOperatorCode;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  @override
  String get paymentMethodCode => 'FPX';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'FPX',
    'account': account.toJson(),
    'paymentOperatorCode': paymentOperatorCode,
    if (emailAddress != null) 'emailAddress': emailAddress,
  };
}

/// It is India market version of the Offline Bank Transfer which differs in the data which need to be collected and used during a Payment process.
final class IMPSMethod extends PaymentMethod {
  const IMPSMethod({required this.account, this.emailAddress});

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account account;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  @override
  String get paymentMethodCode => 'IMPS';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'IMPS',
    'account': account.toJson(),
    if (emailAddress != null) 'emailAddress': emailAddress,
  };
}

/// Mobile Money is a payment method which allows customers to simply complete a payment from their mobile money wallet.
final class MobileMoneyMethod extends PaymentMethod {
  const MobileMoneyMethod({
    required this.account,
    required this.phoneNumber,
    this.paymentOperatorCode,
    this.emailAddress,
  });

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account account;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`.
  final String phoneNumber;

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String? paymentOperatorCode;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  @override
  String get paymentMethodCode => 'MOBILE_MONEY';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'MOBILE_MONEY',
    'account': account.toJson(),
    'phoneNumber': phoneNumber,
    if (paymentOperatorCode != null) 'paymentOperatorCode': paymentOperatorCode,
    if (emailAddress != null) 'emailAddress': emailAddress,
  };
}

/// MoMo is a mobile payment method that allows users to complete transactions via the MoMo app. Payments are initiated through QR codes, where users authorize the transaction within the app.
final class MomoPayMethod extends PaymentMethod {
  const MomoPayMethod({this.emailAddress});

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  @override
  String get paymentMethodCode => 'MOMOPAY';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'MOMOPAY',
    if (emailAddress != null) 'emailAddress': emailAddress,
  };
}

/// Nedbank Direct EFT is a digital payment method that allows customers to pay quickly and securely using their Nedbank app. Instead of entering bank details, customers simply approve the payment on their phone, making the checkout process faster, safer, and more convenient.
final class NedbankDirectEFTMethod extends PaymentMethod {
  const NedbankDirectEFTMethod({required this.account, required this.said, this.emailAddress, this.customerName});

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account account;

  /// min 13, max 13, pattern `^[0-9]*$`.
  final String said;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  /// Customer's first, middle and last name.
  final PersonName? customerName;

  @override
  String get paymentMethodCode => 'NEDBANK_DIRECT_EFT';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'NEDBANK_DIRECT_EFT',
    'account': account.toJson(),
    'said': said,
    if (emailAddress != null) 'emailAddress': emailAddress,
    if (customerName != null) 'customerName': customerName?.toJson(),
  };
}

/// Netbanking, also known as online banking or Net Banking is a payment option offered by banks and financial institutions on Indian market that allow customers to use banking services over the internet. In our case, we take advantage of the Netbanking services to offer your customer UPI Payment method to pay funds directly from your customer Net Banking account.
final class NetBankingMethod extends PaymentMethod {
  const NetBankingMethod({this.account, this.emailAddress, this.phoneNumber, this.paymentOperatorCode});

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account? account;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`.
  final String? phoneNumber;

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String? paymentOperatorCode;

  @override
  String get paymentMethodCode => 'NETBANKING';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'NETBANKING',
    if (account != null) 'account': account?.toJson(),
    if (emailAddress != null) 'emailAddress': emailAddress,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    if (paymentOperatorCode != null) 'paymentOperatorCode': paymentOperatorCode,
  };
}

/// Offline Bank Transfer. Payment method which requires customer to copy Payment instruction from the Payment application right after the incoming payment is submitted and create the Payment transfer using the instructions within customer's own payment service such as Internet or mobile banking or wallet.
final class OfflineMethod extends PaymentMethod {
  const OfflineMethod({
    this.account,
    this.paymentOperatorCode,
    this.emailAddress,
    this.phoneNumber,
    this.productId,
    this.taxId,
    this.customerName,
  });

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account? account;

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String? paymentOperatorCode;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`.
  final String? phoneNumber;

  /// Identification of a product related to a payment order. max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String? productId;

  /// Tax payer identification number of a customer. min 8, max 18.
  final String? taxId;

  /// Customer's first, middle and last name.
  final PersonName? customerName;

  @override
  String get paymentMethodCode => 'OFFLINE';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'OFFLINE',
    if (account != null) 'account': account?.toJson(),
    if (paymentOperatorCode != null) 'paymentOperatorCode': paymentOperatorCode,
    if (emailAddress != null) 'emailAddress': emailAddress,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    if (productId != null) 'productId': productId,
    if (taxId != null) 'taxId': taxId,
    if (customerName != null) 'customerName': customerName?.toJson(),
  };
}

/// Online Bank Transfer. Payment method where Customer is redirected to his own preferred Payment service application right after the payment is submitted and create the Payment transfer with pre-filled Payment instruction.
final class OnlineMethod extends PaymentMethod {
  const OnlineMethod({this.account, this.paymentOperatorCode, this.emailAddress});

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account? account;

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String? paymentOperatorCode;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  @override
  String get paymentMethodCode => 'ONLINE';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'ONLINE',
    if (account != null) 'account': account?.toJson(),
    if (paymentOperatorCode != null) 'paymentOperatorCode': paymentOperatorCode,
    if (emailAddress != null) 'emailAddress': emailAddress,
  };
}

/// OTT Voucher is a cash-to-digital payment method that enables customers to make secure online payments using prepaid vouchers. Rather than relying on a credit card or bank account, customers simply enter a unique 12-digit PIN at checkout, creating an accessible, safe, and seamless payment experience.
final class OttVoucherMethod extends PaymentMethod {
  const OttVoucherMethod({
    required this.voucherPin,
    required this.phoneNumber,
    required this.emailAddress,
    required this.customerName,
  });

  /// OTT voucher PIN. min 1.
  final String voucherPin;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`.
  final String phoneNumber;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String emailAddress;

  /// Person's first, middle and last name.
  final PersonName customerName;

  @override
  String get paymentMethodCode => 'OTT_VOUCHER';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'OTT_VOUCHER',
    'voucherPin': voucherPin,
    'phoneNumber': phoneNumber,
    'emailAddress': emailAddress,
    'customerName': customerName.toJson(),
  };
}

/// Phone to Account. Payment method which requires customer to scan QR code from the Payment application by Customer's Payment service application right after the payment is submitted.
final class P2AV2Method extends PaymentMethod {
  const P2AV2Method({required this.paymentOperatorCode, this.account, this.emailAddress});

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String paymentOperatorCode;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account? account;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  @override
  String get paymentMethodCode => 'P2A_V2';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'P2A_V2',
    'paymentOperatorCode': paymentOperatorCode,
    if (account != null) 'account': account?.toJson(),
    if (emailAddress != null) 'emailAddress': emailAddress,
  };
}

/// PayShap offers a quick, easy, and secure way to send money without having to input banking login details. Customers can make payments using just a phone number or account number, with transactions processed instantly.
final class PayShapMethod extends PaymentMethod {
  const PayShapMethod({
    required this.paymentOperatorCode,
    this.account,
    this.phoneNumber,
    this.emailAddress,
    this.passportNumber,
    this.said,
    this.customerName,
    this.externalProviderCode,
  });

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String paymentOperatorCode;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account? account;

  /// Your customer's mobile phone number, starting with 0. min 12, max 12.
  final String? phoneNumber;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  /// min 8, max 9, pattern `^[a-zA-Z][0-9]+$`.
  final String? passportNumber;

  /// min 13, max 13, pattern `^[0-9]*$`.
  final String? said;

  /// Customer's first, middle and last name.
  final PersonName? customerName;

  /// min 1.
  final String? externalProviderCode;

  @override
  String get paymentMethodCode => 'PAYSHAP';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'PAYSHAP',
    'paymentOperatorCode': paymentOperatorCode,
    if (account != null) 'account': account?.toJson(),
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    if (emailAddress != null) 'emailAddress': emailAddress,
    if (passportNumber != null) 'passportNumber': passportNumber,
    if (said != null) 'said': said,
    if (customerName != null) 'customerName': customerName?.toJson(),
    if (externalProviderCode != null) 'externalProviderCode': externalProviderCode,
  };
}

/// Pay Me is payment method intended for South Africa market which allows customers to send payments by scanning QR codes from supported banks and e-wallets.
final class PayMeMethod extends PaymentMethod {
  const PayMeMethod({required this.account, this.emailAddress, this.phoneNumber});

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account account;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`.
  final String? phoneNumber;

  @override
  String get paymentMethodCode => 'PAY_ME';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'PAY_ME',
    'account': account.toJson(),
    if (emailAddress != null) 'emailAddress': emailAddress,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
  };
}

/// Pix is a Brazilian payment method which allows customers to send payments using their preferred banking app by either scanning QR code or copy-pasting Pix EMV code.
final class PixQRMethod extends PaymentMethod {
  const PixQRMethod({required this.account, required this.taxId});

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account account;

  /// Brazilian tax payer identification number - CPF for individuals / CNPJ for businesses. min 14, max 14.
  final String taxId;

  @override
  String get paymentMethodCode => 'PIXQR';

  @override
  Map<String, Object?> toJson() => {'paymentMethodCode': 'PIXQR', 'account': account.toJson(), 'taxId': taxId};
}

/// Payment method which requires customer to scan QR code from the Payment application by Customer's Payment service application right after the payment is submitted.
final class PromptPayMethod extends PaymentMethod {
  const PromptPayMethod({this.account, this.paymentOperatorCode, this.emailAddress});

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account? account;

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String? paymentOperatorCode;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  @override
  String get paymentMethodCode => 'PROMPTPAY';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'PROMPTPAY',
    if (account != null) 'account': account?.toJson(),
    if (paymentOperatorCode != null) 'paymentOperatorCode': paymentOperatorCode,
    if (emailAddress != null) 'emailAddress': emailAddress,
  };
}

/// PSE (Pagos Seguros en L?nea) is a real-time online payment system in Colombia that enables secure, instant bank transfer payments - customers simply log in into their internet banking and authorize pre-populated payment details.
final class PseMethod extends PaymentMethod {
  const PseMethod({required this.account, required this.emailAddress, required this.phoneNumber});

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account account;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String emailAddress;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`.
  final String phoneNumber;

  @override
  String get paymentMethodCode => 'PSE';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'PSE',
    'account': account.toJson(),
    'emailAddress': emailAddress,
    'phoneNumber': phoneNumber,
  };
}

/// QRIS is payment method intended for the Indonesian market which allows users to pay using scanning QR codes by theirs Payment application.
final class QrisPayMethod extends PaymentMethod {
  const QrisPayMethod({this.account, this.emailAddress});

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account? account;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  @override
  String get paymentMethodCode => 'QRISPAY';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'QRISPAY',
    if (account != null) 'account': account?.toJson(),
    if (emailAddress != null) 'emailAddress': emailAddress,
  };
}

/// QR Ph is payment method intended for Philippine market which allows customers to send payments by scanning QR codes from supported banks and e-wallets.
final class QrPhMethod extends PaymentMethod {
  const QrPhMethod({this.account, this.emailAddress, this.paymentOperatorCode, this.phoneNumber});

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account? account;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String? paymentOperatorCode;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`.
  final String? phoneNumber;

  @override
  String get paymentMethodCode => 'QRPH';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'QRPH',
    if (account != null) 'account': account?.toJson(),
    if (emailAddress != null) 'emailAddress': emailAddress,
    if (paymentOperatorCode != null) 'paymentOperatorCode': paymentOperatorCode,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
  };
}

/// SnapScan is a QR-based payment method that allows customers to make fast and secure payments by scanning a QR code using the SnapScan app or by clicking on the payment deep link.
final class SnapScanQrMethod extends PaymentMethod {
  const SnapScanQrMethod({required this.emailAddress, required this.customerName});

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String emailAddress;

  /// Person's first, middle and last name.
  final PersonName customerName;

  @override
  String get paymentMethodCode => 'SNAPSCAN_QR';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'SNAPSCAN_QR',
    'emailAddress': emailAddress,
    'customerName': customerName.toJson(),
  };
}

/// UPI Collect is a method of fund transfers in India. This payment method allows users to simply authorize payments through their registered UPI app after receiving a payment collection request.
final class UpiCollectMethod extends PaymentMethod {
  const UpiCollectMethod({
    required this.account,
    required this.upiId,
    required this.emailAddress,
    required this.phoneNumber,
  });

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account account;

  /// Virtual payment address of the customer on UPI provided by the merchant or obtained during the processing on our platform. max 100, pattern `[a-zA-Z0-9_\-\.]+@[a-zA-Z0-9_\.]+`.
  final String upiId;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String emailAddress;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`.
  final String phoneNumber;

  @override
  String get paymentMethodCode => 'UPICOLLECT';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'UPICOLLECT',
    'account': account.toJson(),
    'upiId': upiId,
    'emailAddress': emailAddress,
    'phoneNumber': phoneNumber,
  };
}

/// UPI (Unified Payments Interface) is a method of fund transfers in India. The mechanism allows two parties to exchange funds using a UPI ID without having to share the banking information with the other party.
final class UpiIdMethod extends PaymentMethod {
  const UpiIdMethod({required this.upiId, this.emailAddress});

  /// Virtual payment address of the customer on UPI provided by the merchant or obtained during the processing on our platform. max 100, pattern `[a-zA-Z0-9_\-\.]+@[a-zA-Z0-9_\.]+`.
  final String upiId;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  @override
  String get paymentMethodCode => 'UPIID';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'UPIID',
    'upiId': upiId,
    if (emailAddress != null) 'emailAddress': emailAddress,
  };
}

/// UPI QR is payment method intended for the Indian market. This payment method requires customers to scan QR code by Customer's Payment service application compatible with UPI payment schema.
final class UpiQRMethod extends PaymentMethod {
  const UpiQRMethod({this.account, this.upiId, this.emailAddress, this.phoneNumber, this.paymentOperatorCode});

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account? account;

  /// Virtual payment address of the customer on UPI provided by the merchant or obtained during the processing on our platform. max 100, pattern `[a-zA-Z0-9_\-\.]+@[a-zA-Z0-9_\.]+`.
  final String? upiId;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`.
  final String? phoneNumber;

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String? paymentOperatorCode;

  @override
  String get paymentMethodCode => 'UPIQR';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'UPIQR',
    if (account != null) 'account': account?.toJson(),
    if (upiId != null) 'upiId': upiId,
    if (emailAddress != null) 'emailAddress': emailAddress,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    if (paymentOperatorCode != null) 'paymentOperatorCode': paymentOperatorCode,
  };
}

/// Virtual Accounts. Payment method which requires customer to copy Payment instruction with generated Virtual Account from the Payment application right after the payment is submitted and create the Payment transfer using the instructions within customer's own payment service such as Internet or mobile banking, wallet or ATM.
final class VaPayMethod extends PaymentMethod {
  const VaPayMethod({
    this.account,
    this.paymentOperatorCode,
    this.emailAddress,
    this.phoneNumber,
    this.paymentLocation,
  });

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account? account;

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String? paymentOperatorCode;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`.
  final String? phoneNumber;

  /// Specifies location where a customer is making the payment (e.g.
  final PaymentLocation? paymentLocation;

  @override
  String get paymentMethodCode => 'VAPAY';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'VAPAY',
    if (account != null) 'account': account?.toJson(),
    if (paymentOperatorCode != null) 'paymentOperatorCode': paymentOperatorCode,
    if (emailAddress != null) 'emailAddress': emailAddress,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    if (paymentLocation != null) 'paymentLocation': paymentLocation?.toJson(),
  };
}

/// Virtual Accounts With Verified Bank Account. Payment method which requires customer to copy Payment instruction with assigned Virtual Account from the Payment application right after the payment is submitted and create the Payment transfer using the instructions within customer's own payment service such as Internet or mobile banking, wallet or ATM.
final class VaPayVerifMethod extends PaymentMethod {
  const VaPayVerifMethod({required this.account, required this.paymentOperatorCode, this.emailAddress});

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final Account account;

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String paymentOperatorCode;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  @override
  String get paymentMethodCode => 'VAPAY_VERIF';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'VAPAY_VERIF',
    'account': account.toJson(),
    'paymentOperatorCode': paymentOperatorCode,
    if (emailAddress != null) 'emailAddress': emailAddress,
  };
}

/// Viet QR is a payment method intended for the Vietnamese market which allows users to pay using scanning QR codes by theirs payment application or internet banking.
final class VietQRMethod extends PaymentMethod {
  const VietQRMethod({required this.paymentOperatorCode, this.emailAddress});

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String paymentOperatorCode;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  @override
  String get paymentMethodCode => 'VIETQR';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'VIETQR',
    'paymentOperatorCode': paymentOperatorCode,
    if (emailAddress != null) 'emailAddress': emailAddress,
  };
}

/// Zapper is a QR-based payment method that allows customers to make fast and secure payments by scanning a QR code using the Zapper app or by clicking on the payment deep link.
final class ZapperQrMethod extends PaymentMethod {
  const ZapperQrMethod({required this.emailAddress, required this.customerName});

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String emailAddress;

  /// Customer's first and last name.
  final PersonName customerName;

  @override
  String get paymentMethodCode => 'ZAPPER_QR';

  @override
  Map<String, Object?> toJson() => {
    'paymentMethodCode': 'ZAPPER_QR',
    'emailAddress': emailAddress,
    'customerName': customerName.toJson(),
  };
}

/// The payer's bank or wallet account. Each method needs different fields and checks them when it is sent.
final class Account extends SynqtModel {
  const Account({this.accountName, this.accountNumber, this.accountType});

  /// Account Name is the name of the person who holds the bank or wallet account which your customer sends funds from to make his payment. Rules differ per payment method.
  final String? accountName;

  /// Account Number is the number of your customer's bank account which your customer sends funds from to make his payment. Rules differ per payment method.
  final String? accountNumber;

  /// The customer's account type. Rules differ per payment method.
  final String? accountType;

  @override
  Map<String, Object?> toJson() => {
    if (accountName != null) 'accountName': accountName,
    if (accountNumber != null) 'accountNumber': accountNumber,
    if (accountType != null) 'accountType': accountType,
  };
}

final class CardData extends SynqtModel {
  const CardData({this.cardDataVault});

  final CardDataVault? cardDataVault;

  @override
  Map<String, Object?> toJson() => {if (cardDataVault != null) 'cardDataVault': cardDataVault?.toJson()};
}

final class CardDataVault extends SynqtModel {
  const CardDataVault({required this.vaultToken, this.securityCode});

  /// min 1.
  final String vaultToken;
  final EnvelopeEncryption? securityCode;

  @override
  Map<String, Object?> toJson() => {
    'vaultToken': vaultToken,
    if (securityCode != null) 'securityCode': securityCode?.toJson(),
  };
}

final class CardPaymentContact extends SynqtModel {
  const CardPaymentContact({
    this.addressLines,
    this.administrativeArea,
    this.country,
    this.countryCode,
    this.locality,
    this.postalCode,
    this.personName,
    this.emailAddress,
    this.phoneNumber,
  });

  final List<String>? addressLines;

  /// min 1.
  final String? administrativeArea;

  /// min 1.
  final String? country;

  /// min 1.
  final String? countryCode;

  /// min 1.
  final String? locality;

  /// min 1.
  final String? postalCode;

  /// Person's first, middle and last name.
  final PersonName? personName;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`.
  final String? phoneNumber;

  @override
  Map<String, Object?> toJson() => {
    if (addressLines != null) 'addressLines': addressLines,
    if (administrativeArea != null) 'administrativeArea': administrativeArea,
    if (country != null) 'country': country,
    if (countryCode != null) 'countryCode': countryCode,
    if (locality != null) 'locality': locality,
    if (postalCode != null) 'postalCode': postalCode,
    if (personName != null) 'personName': personName?.toJson(),
    if (emailAddress != null) 'emailAddress': emailAddress,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
  };
}

final class CardPaymentContacts extends SynqtModel {
  const CardPaymentContacts({this.billingContact, this.shippingContact});

  final CardPaymentContact? billingContact;
  final CardPaymentContact? shippingContact;

  @override
  Map<String, Object?> toJson() => {
    if (billingContact != null) 'billingContact': billingContact?.toJson(),
    if (shippingContact != null) 'shippingContact': shippingContact?.toJson(),
  };
}

final class EnvelopeEncryption extends SynqtModel {
  const EnvelopeEncryption({
    required this.cipherText,
    required this.wrappedDEK,
    required this.initializationVector,
    required this.kekId,
  });

  /// min 1.
  final String cipherText;

  /// min 1.
  final String wrappedDEK;

  /// min 1.
  final String initializationVector;

  /// min 1.
  final String kekId;

  @override
  Map<String, Object?> toJson() => {
    'cipherText': cipherText,
    'wrappedDEK': wrappedDEK,
    'initializationVector': initializationVector,
    'kekId': kekId,
  };
}

final class PaymentLocation extends SynqtModel {
  const PaymentLocation({required this.postalCode, required this.city, required this.district});

  /// Postal code where customer is paying at (e.g. min 1.
  final String postalCode;

  /// City which customer is paying in (e.g. min 1.
  final String city;

  /// Disctrict which customer is paying in (e.g. min 1.
  final String district;

  @override
  Map<String, Object?> toJson() => {'postalCode': postalCode, 'city': city, 'district': district};

  factory PaymentLocation.fromJson(Map<String, Object?> json) => PaymentLocation(
    postalCode: json['postalCode'] as String,
    city: json['city'] as String,
    district: json['district'] as String,
  );
}

/// A person's name. Each method needs different parts and checks them when it is sent.
final class PersonName extends SynqtModel {
  const PersonName({this.titleBefore, this.firstName, this.middleName, this.lastName, this.titleAfter});

  /// A title before the name. min 1.
  final String? titleBefore;

  /// A first name. min 1.
  final String? firstName;

  /// A middle name. min 1.
  final String? middleName;

  /// A last name. min 1.
  final String? lastName;

  /// A title after the name. min 1.
  final String? titleAfter;

  @override
  Map<String, Object?> toJson() => {
    if (titleBefore != null) 'titleBefore': titleBefore,
    if (firstName != null) 'firstName': firstName,
    if (middleName != null) 'middleName': middleName,
    if (lastName != null) 'lastName': lastName,
    if (titleAfter != null) 'titleAfter': titleAfter,
  };
}

final class RecurringPayment extends SynqtModel {
  const RecurringPayment({required this.isFixedAmount, required this.isFixedPeriod, this.idOfInitialTransaction});

  final bool isFixedAmount;
  final bool isFixedPeriod;
  final String? idOfInitialTransaction;

  @override
  Map<String, Object?> toJson() => {
    'isFixedAmount': isFixedAmount,
    'isFixedPeriod': isFixedPeriod,
    if (idOfInitialTransaction != null) 'idOfInitialTransaction': idOfInitialTransaction,
  };
}

/// Throws [SynqtArgumentException] when a shared type such as [Account] lacks a field this method needs, or has one it does
/// not take.
void validatePaymentMethod(PaymentMethod method) {
  switch (method) {
    case final AbsaPayMethod model:
      _check(
        model.account == null || model.account?.accountType == null,
        'AbsaPayMethod does not take account.accountType',
      );
      _check(
        model.customerName == null || model.customerName?.lastName != null,
        'AbsaPayMethod needs customerName.lastName',
      );
    case final CapitecPayMethod model:
      _check(
        model.account == null || model.account?.accountType == null,
        'CapitecPayMethod does not take account.accountType',
      );
      _check(
        model.customerName == null || model.customerName?.lastName != null,
        'CapitecPayMethod needs customerName.lastName',
      );
    case final CardMethod model:
      if (model.paymentContacts != null) _validateCardPaymentContacts(model.paymentContacts!);
    case final CodePaymentMethod model:
      _check(
        model.account == null || model.account?.accountName != null,
        'CodePaymentMethod needs account.accountName',
      );
      _check(
        model.account == null || model.account?.accountNumber == null,
        'CodePaymentMethod does not take account.accountNumber',
      );
      _check(
        model.account == null || model.account?.accountType == null,
        'CodePaymentMethod does not take account.accountType',
      );
    case final DuitNowMethod model:
      _check(model.account.accountName != null, 'DuitNowMethod needs account.accountName');
      _check(model.account.accountType == null, 'DuitNowMethod does not take account.accountType');
    case final EWalletMethod model:
      _check(
        model.account == null || model.account?.accountNumber == null,
        'EWalletMethod does not take account.accountNumber',
      );
      _check(
        model.account == null || model.account?.accountType == null,
        'EWalletMethod does not take account.accountType',
      );
    case final FnbDirectEFTMethod model:
      _check(model.customerName.firstName != null, 'FnbDirectEFTMethod needs customerName.firstName');
      _check(model.customerName.lastName != null, 'FnbDirectEFTMethod needs customerName.lastName');
      _check(model.customerName.titleBefore == null, 'FnbDirectEFTMethod does not take customerName.titleBefore');
      _check(model.customerName.middleName == null, 'FnbDirectEFTMethod does not take customerName.middleName');
      _check(model.customerName.titleAfter == null, 'FnbDirectEFTMethod does not take customerName.titleAfter');
      _check(model.account.accountNumber != null, 'FnbDirectEFTMethod needs account.accountNumber');
      _check(model.account.accountName == null, 'FnbDirectEFTMethod does not take account.accountName');
      _check(model.account.accountType == null, 'FnbDirectEFTMethod does not take account.accountType');
    case final FpxMethod model:
      _check(model.account.accountName != null, 'FpxMethod needs account.accountName');
      _check(model.account.accountType != null, 'FpxMethod needs account.accountType');
      _check(model.account.accountNumber == null, 'FpxMethod does not take account.accountNumber');
    case final IMPSMethod model:
      _check(model.account.accountName != null, 'IMPSMethod needs account.accountName');
      _check(model.account.accountType == null, 'IMPSMethod does not take account.accountType');
    case final MobileMoneyMethod model:
      _check(model.account.accountName != null, 'MobileMoneyMethod needs account.accountName');
      _check(model.account.accountNumber == null, 'MobileMoneyMethod does not take account.accountNumber');
      _check(model.account.accountType == null, 'MobileMoneyMethod does not take account.accountType');
    case final NedbankDirectEFTMethod model:
      _check(model.account.accountName != null, 'NedbankDirectEFTMethod needs account.accountName');
      _check(model.account.accountNumber == null, 'NedbankDirectEFTMethod does not take account.accountNumber');
      _check(model.account.accountType == null, 'NedbankDirectEFTMethod does not take account.accountType');
      _check(
        model.customerName == null || model.customerName?.lastName != null,
        'NedbankDirectEFTMethod needs customerName.lastName',
      );
    case final NetBankingMethod model:
      _check(
        model.account == null || model.account?.accountType == null,
        'NetBankingMethod does not take account.accountType',
      );
    case final OfflineMethod model:
      _check(
        model.account == null || model.account?.accountType == null,
        'OfflineMethod does not take account.accountType',
      );
      _check(
        model.customerName == null || model.customerName?.firstName != null,
        'OfflineMethod needs customerName.firstName',
      );
      _check(
        model.customerName == null || model.customerName?.lastName != null,
        'OfflineMethod needs customerName.lastName',
      );
    case final OttVoucherMethod model:
      _check(model.customerName.firstName != null, 'OttVoucherMethod needs customerName.firstName');
      _check(model.customerName.lastName != null, 'OttVoucherMethod needs customerName.lastName');
    case final P2AV2Method model:
      _check(
        model.account == null || model.account?.accountType == null,
        'P2AV2Method does not take account.accountType',
      );
    case final PayShapMethod model:
      _check(
        model.account == null || model.account?.accountType == null,
        'PayShapMethod does not take account.accountType',
      );
      _check(
        model.customerName == null || model.customerName?.lastName != null,
        'PayShapMethod needs customerName.lastName',
      );
    case final PayMeMethod model:
      _check(model.account.accountName != null, 'PayMeMethod needs account.accountName');
      _check(model.account.accountType == null, 'PayMeMethod does not take account.accountType');
    case final PixQRMethod model:
      _check(model.account.accountName != null, 'PixQRMethod needs account.accountName');
      _check(model.account.accountNumber == null, 'PixQRMethod does not take account.accountNumber');
      _check(model.account.accountType == null, 'PixQRMethod does not take account.accountType');
    case final PromptPayMethod model:
      _check(
        model.account == null || model.account?.accountNumber != null,
        'PromptPayMethod needs account.accountNumber',
      );
      _check(
        model.account == null || model.account?.accountType == null,
        'PromptPayMethod does not take account.accountType',
      );
    case final PseMethod model:
      _check(model.account.accountName != null, 'PseMethod needs account.accountName');
      _check(model.account.accountNumber == null, 'PseMethod does not take account.accountNumber');
      _check(model.account.accountType == null, 'PseMethod does not take account.accountType');
    case final QrisPayMethod model:
      _check(
        model.account == null || model.account?.accountType == null,
        'QrisPayMethod does not take account.accountType',
      );
    case final QrPhMethod model:
      _check(
        model.account == null || model.account?.accountType == null,
        'QrPhMethod does not take account.accountType',
      );
    case final SnapScanQrMethod model:
      _check(model.customerName.firstName != null, 'SnapScanQrMethod needs customerName.firstName');
      _check(model.customerName.lastName != null, 'SnapScanQrMethod needs customerName.lastName');
    case final UpiCollectMethod model:
      _check(model.account.accountName != null, 'UpiCollectMethod needs account.accountName');
      _check(model.account.accountNumber == null, 'UpiCollectMethod does not take account.accountNumber');
      _check(model.account.accountType == null, 'UpiCollectMethod does not take account.accountType');
    case final UpiQRMethod model:
      _check(
        model.account == null || model.account?.accountNumber == null,
        'UpiQRMethod does not take account.accountNumber',
      );
      _check(
        model.account == null || model.account?.accountType == null,
        'UpiQRMethod does not take account.accountType',
      );
    case final VaPayMethod model:
      _check(
        model.account == null || model.account?.accountType == null,
        'VaPayMethod does not take account.accountType',
      );
    case final VaPayVerifMethod model:
      _check(model.account.accountNumber != null, 'VaPayVerifMethod needs account.accountNumber');
      _check(model.account.accountType == null, 'VaPayVerifMethod does not take account.accountType');
    case final ZapperQrMethod model:
      _check(model.customerName.firstName != null, 'ZapperQrMethod needs customerName.firstName');
      _check(model.customerName.lastName != null, 'ZapperQrMethod needs customerName.lastName');
      _check(model.customerName.titleBefore == null, 'ZapperQrMethod does not take customerName.titleBefore');
      _check(model.customerName.middleName == null, 'ZapperQrMethod does not take customerName.middleName');
      _check(model.customerName.titleAfter == null, 'ZapperQrMethod does not take customerName.titleAfter');
    default:
      break;
  }
}

void _validateCardPaymentContact(CardPaymentContact model) {
  _check(
    model.personName == null || model.personName?.lastName != null,
    'CardPaymentContact needs personName.lastName',
  );
}

void _validateCardPaymentContacts(CardPaymentContacts model) {
  if (model.billingContact != null) _validateCardPaymentContact(model.billingContact!);
  if (model.shippingContact != null) _validateCardPaymentContact(model.shippingContact!);
}

/// `paymentMethodResponse` of a created payin, one subclass per method. Unknown methods read as [UnknownPaymentMethodResponse].
sealed class PaymentMethodResponse {
  const PaymentMethodResponse();

  String get paymentMethodCode;

  /// Throws when a field has an unexpected type; callers fall back to [UnknownPaymentMethodResponse].
  factory PaymentMethodResponse.fromJson(Map<String, Object?> json) =>
      switch (json['paymentMethodCode'] as String? ?? '') {
        'ABSA_PAY' => AbsaPayResponse.fromJson(json),
        'CAPITEC_PAY' => CapitecPayResponse.fromJson(json),
        'CARD' => CardResponse.fromJson(json),
        'CODE_PAYMENT' => CodePaymentResponse.fromJson(json),
        'CRYPTO_OFFLINE' => CryptoOfflineResponse.fromJson(json),
        'DUITNOW' => DuitNowResponse.fromJson(json),
        'EWALLET' => EWalletResponse.fromJson(json),
        'FNB_DIRECT_EFT' => FnbDirectEFTResponse.fromJson(json),
        'FPX' => FpxResponse.fromJson(json),
        'IMPS' => IMPSResponse.fromJson(json),
        'MOBILE_MONEY' => MobileMoneyResponse.fromJson(json),
        'MOMOPAY' => MomoPayResponse.fromJson(json),
        'NEDBANK_DIRECT_EFT' => NedbankDirectEFTResponse.fromJson(json),
        'NETBANKING' => NetBankingResponse.fromJson(json),
        'OFFLINE' => OfflineResponse.fromJson(json),
        'ONLINE' => OnlineResponse.fromJson(json),
        'OTT_VOUCHER' => OttVoucherResponse.fromJson(json),
        'P2A_V2' => P2AV2Response.fromJson(json),
        'PAYSHAP' => PayShapResponse.fromJson(json),
        'PAY_ME' => PayMeResponse.fromJson(json),
        'PIXQR' => PixQRResponse.fromJson(json),
        'PROMPTPAY' => PromptPayResponse.fromJson(json),
        'PSE' => PseResponse.fromJson(json),
        'QRISPAY' => QrisPayResponse.fromJson(json),
        'QRPH' => QrPhResponse.fromJson(json),
        'SNAPSCAN_QR' => SnapScanQrResponse.fromJson(json),
        'UPICOLLECT' => UpiCollectResponse.fromJson(json),
        'UPIID' => UpiIdResponse.fromJson(json),
        'UPIQR' => UpiQRResponse.fromJson(json),
        'VAPAY' => VaPayResponse.fromJson(json),
        'VAPAY_VERIF' => VaPayVerifResponse.fromJson(json),
        'VIETQR' => VietQRResponse.fromJson(json),
        'ZAPPER_QR' => ZapperQrResponse.fromJson(json),
        final code => UnknownPaymentMethodResponse(code),
      };
}

/// A `paymentMethodCode` this SDK version does not know yet; new values are non-breaking API changes.
final class UnknownPaymentMethodResponse extends PaymentMethodResponse {
  const UnknownPaymentMethodResponse(this.paymentMethodCode);

  @override
  final String paymentMethodCode;

  @override
  bool operator ==(Object other) =>
      other is UnknownPaymentMethodResponse && other.paymentMethodCode == paymentMethodCode;

  @override
  int get hashCode => paymentMethodCode.hashCode;

  @override
  String toString() => 'UnknownPaymentMethodResponse($paymentMethodCode)';
}

final class AbsaPayResponse extends PaymentMethodResponse {
  const AbsaPayResponse({
    this.idPayin,
    this.idPayment,
    this.accounts,
    this.accountCustomer,
    this.accountCustomerUsedForPayment,
    this.passportNumber,
    this.said,
    this.money,
    this.vat,
    this.reference,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;
  final List<AccountResponse>? accounts;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final AccountResponse? accountCustomer;

  /// Contains information about the account used by the customer.
  final AccountResponse? accountCustomerUsedForPayment;

  /// min 8, max 9, pattern `^[a-zA-Z][0-9]+$`.
  final String? passportNumber;

  /// min 13, max 13, pattern `^[0-9]*$`.
  final String? said;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'ABSA_PAY';

  factory AbsaPayResponse.fromJson(Map<String, Object?> json) => AbsaPayResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    accounts: (json['accounts'] as List?)
        ?.map((item) => AccountResponse.fromJson(item as Map<String, Object?>))
        .toList(),
    accountCustomer: _obj(json['accountCustomer'], AccountResponse.fromJson),
    accountCustomerUsedForPayment: _obj(json['accountCustomerUsedForPayment'], AccountResponse.fromJson),
    passportNumber: json['passportNumber'] as String?,
    said: json['said'] as String?,
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    reference: json['reference'] as String?,
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class CapitecPayResponse extends PaymentMethodResponse {
  const CapitecPayResponse({
    this.idPayin,
    this.idPayment,
    this.money,
    this.vat,
    this.merchantName,
    this.accountCustomer,
    this.accountCustomerUsedForPayment,
    this.phoneNumber,
    this.said,
    this.reference,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final AccountResponse? accountCustomer;

  /// Contains information about the account used by the customer.
  final AccountResponse? accountCustomerUsedForPayment;

  /// Your customer's mobile phone number, starting with 0. min 12, max 12.
  final String? phoneNumber;

  /// min 13, max 13, pattern `^[0-9]*$`.
  final String? said;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'CAPITEC_PAY';

  factory CapitecPayResponse.fromJson(Map<String, Object?> json) => CapitecPayResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    accountCustomer: _obj(json['accountCustomer'], AccountResponse.fromJson),
    accountCustomerUsedForPayment: _obj(json['accountCustomerUsedForPayment'], AccountResponse.fromJson),
    phoneNumber: json['phoneNumber'] as String?,
    said: json['said'] as String?,
    reference: json['reference'] as String?,
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class CardResponse extends PaymentMethodResponse {
  const CardResponse({
    this.idPayin,
    this.idPayment,
    this.money,
    this.vat,
    this.reference,
    this.returnUrl,
    this.paymentOperator,
    this.acceptedAt,
    this.expireAt,
    this.userInteraction,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// PaymentOperator is a financial institution that manages transactions in your customer's account (such as banks, card payment processors, mobile wallets and so on).
  final SelectedPaymentOperatorIncomingResponse? paymentOperator;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  /// TODO:
  final UserInteraction? userInteraction;

  @override
  String get paymentMethodCode => 'CARD';

  factory CardResponse.fromJson(Map<String, Object?> json) => CardResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    reference: json['reference'] as String?,
    returnUrl: json['returnUrl'] as String?,
    paymentOperator: _obj(json['paymentOperator'], SelectedPaymentOperatorIncomingResponse.fromJson),
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
    userInteraction: _obj(json['userInteraction'], UserInteraction.fromJson),
  );
}

final class CodePaymentResponse extends PaymentMethodResponse {
  const CodePaymentResponse({
    this.idPayin,
    this.idPayment,
    this.account,
    this.accountCustomer,
    this.emailAddress,
    this.phoneNumber,
    this.paymentLocationCustomer,
    this.money,
    this.vat,
    this.reference,
    this.returnUrl,
    this.paymentOperator,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Parameters of a Convenience Store Payment that your customer use to send funds to make a payment. Always present per spec.
  final AccountResponse? account;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from. Always present per spec.
  final AccountResponse? accountCustomer;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins. Always present per spec.
  final String? emailAddress;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`. Always present per spec.
  final String? phoneNumber;

  /// Specifies location where a customer is making the payment (e.g. Always present per spec.
  final PaymentLocation? paymentLocationCustomer;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// PaymentOperator is a financial institution that manages transactions in your customer's account (such as banks, card payment processors, mobile wallets and so on). Always present per spec.
  final SelectedPaymentOperatorIncomingResponse? paymentOperator;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'CODE_PAYMENT';

  factory CodePaymentResponse.fromJson(Map<String, Object?> json) => CodePaymentResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    account: _obj(json['account'], AccountResponse.fromJson),
    accountCustomer: _obj(json['accountCustomer'], AccountResponse.fromJson),
    emailAddress: json['emailAddress'] as String?,
    phoneNumber: json['phoneNumber'] as String?,
    paymentLocationCustomer: _obj(json['paymentLocationCustomer'], PaymentLocation.fromJson),
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    reference: json['reference'] as String?,
    returnUrl: json['returnUrl'] as String?,
    paymentOperator: _obj(json['paymentOperator'], SelectedPaymentOperatorIncomingResponse.fromJson),
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class CryptoOfflineResponse extends PaymentMethodResponse {
  const CryptoOfflineResponse({
    this.idPayin,
    this.idPayment,
    this.account,
    this.money,
    this.vat,
    this.merchantName,
    this.reference,
    this.qrName,
    this.qrCode,
    this.paymentOperator,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Parameters of a crypto wallet where we expect that your customer send funds to make a payment. Always present per spec.
  final AccountResponse? account;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// The name of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrName;

  /// The URL of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrCode;

  /// PaymentOperator is a financial institution that manages transactions in your customer's account (such as banks, card payment processors, mobile wallets and so on). Always present per spec.
  final SelectedPaymentOperatorIncomingResponse? paymentOperator;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'CRYPTO_OFFLINE';

  factory CryptoOfflineResponse.fromJson(Map<String, Object?> json) => CryptoOfflineResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    account: _obj(json['account'], AccountResponse.fromJson),
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    reference: json['reference'] as String?,
    qrName: json['qrName'] as String?,
    qrCode: json['qrCode'] as String?,
    paymentOperator: _obj(json['paymentOperator'], SelectedPaymentOperatorIncomingResponse.fromJson),
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class DuitNowResponse extends PaymentMethodResponse {
  const DuitNowResponse({
    this.idPayin,
    this.idPayment,
    this.accountCustomer,
    this.money,
    this.vat,
    this.moneyRequired,
    this.merchantName,
    this.reference,
    this.qrName,
    this.qrCode,
    this.paymentOperator,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from. Always present per spec.
  final AccountResponse? accountCustomer;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;
  final MoneyResponse? moneyRequired;

  /// Always present per spec.
  final String? merchantName;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// The name of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrName;

  /// The URL of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrCode;

  /// PaymentOperator is a financial institution that manages transactions in your customer's account (such as banks, card payment processors, mobile wallets and so on).
  final SelectedPaymentOperatorIncomingResponse? paymentOperator;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'DUITNOW';

  factory DuitNowResponse.fromJson(Map<String, Object?> json) => DuitNowResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    accountCustomer: _obj(json['accountCustomer'], AccountResponse.fromJson),
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    moneyRequired: _obj(json['moneyRequired'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    reference: json['reference'] as String?,
    qrName: json['qrName'] as String?,
    qrCode: json['qrCode'] as String?,
    paymentOperator: _obj(json['paymentOperator'], SelectedPaymentOperatorIncomingResponse.fromJson),
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class EWalletResponse extends PaymentMethodResponse {
  const EWalletResponse({
    this.idPayin,
    this.idPayment,
    this.money,
    this.vat,
    this.merchantName,
    this.reference,
    this.paymentOperator,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// PaymentOperator is a financial institution that manages transactions in your customer's account (such as banks, card payment processors, mobile wallets and so on).
  final SelectedPaymentOperatorIncomingResponse? paymentOperator;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'EWALLET';

  factory EWalletResponse.fromJson(Map<String, Object?> json) => EWalletResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    reference: json['reference'] as String?,
    paymentOperator: _obj(json['paymentOperator'], SelectedPaymentOperatorIncomingResponse.fromJson),
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class FnbDirectEFTResponse extends PaymentMethodResponse {
  const FnbDirectEFTResponse({
    this.idPayin,
    this.idPayment,
    this.money,
    this.vat,
    this.merchantName,
    this.emailAddress,
    this.accountCustomer,
    this.passportNumber,
    this.said,
    this.reference,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins. Always present per spec.
  final String? emailAddress;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from. Always present per spec.
  final AccountResponse? accountCustomer;

  /// min 8, max 9, pattern `^[a-zA-Z][0-9]+$`.
  final String? passportNumber;

  /// min 13, max 13, pattern `^[0-9]*$`.
  final String? said;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'FNB_DIRECT_EFT';

  factory FnbDirectEFTResponse.fromJson(Map<String, Object?> json) => FnbDirectEFTResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    emailAddress: json['emailAddress'] as String?,
    accountCustomer: _obj(json['accountCustomer'], AccountResponse.fromJson),
    passportNumber: json['passportNumber'] as String?,
    said: json['said'] as String?,
    reference: json['reference'] as String?,
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class FpxResponse extends PaymentMethodResponse {
  const FpxResponse({
    this.idPayin,
    this.idPayment,
    this.money,
    this.vat,
    this.emailAddress,
    this.reference,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'FPX';

  factory FpxResponse.fromJson(Map<String, Object?> json) => FpxResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    emailAddress: json['emailAddress'] as String?,
    reference: json['reference'] as String?,
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

/// The account parameters for this payment method are used to show payment instructions to the customer.
final class IMPSResponse extends PaymentMethodResponse {
  const IMPSResponse({
    this.idPayin,
    this.idPayment,
    this.account,
    this.money,
    this.vat,
    this.merchantName,
    this.reference,
    this.qrCode,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Parameters of a bank account where we expect that your customer send funds to make a payment. Always present per spec.
  final AccountResponse? account;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// Always present per spec.
  final String? qrCode;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'IMPS';

  factory IMPSResponse.fromJson(Map<String, Object?> json) => IMPSResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    account: _obj(json['account'], AccountResponse.fromJson),
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    reference: json['reference'] as String?,
    qrCode: json['qrCode'] as String?,
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class MobileMoneyResponse extends PaymentMethodResponse {
  const MobileMoneyResponse({
    this.idPayin,
    this.idPayment,
    this.accountCustomer,
    this.emailAddress,
    this.money,
    this.vat,
    this.merchantName,
    this.phoneNumber,
    this.reference,
    this.returnUrl,
    this.paymentOperator,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from. Always present per spec.
  final AccountResponse? accountCustomer;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`. Always present per spec.
  final String? phoneNumber;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// PaymentOperator is a financial institution that manages transactions in your customer's account (such as banks, card payment processors, mobile wallets and so on).
  final SelectedPaymentOperatorIncomingResponse? paymentOperator;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'MOBILE_MONEY';

  factory MobileMoneyResponse.fromJson(Map<String, Object?> json) => MobileMoneyResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    accountCustomer: _obj(json['accountCustomer'], AccountResponse.fromJson),
    emailAddress: json['emailAddress'] as String?,
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    phoneNumber: json['phoneNumber'] as String?,
    reference: json['reference'] as String?,
    returnUrl: json['returnUrl'] as String?,
    paymentOperator: _obj(json['paymentOperator'], SelectedPaymentOperatorIncomingResponse.fromJson),
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class MomoPayResponse extends PaymentMethodResponse {
  const MomoPayResponse({
    this.idPayin,
    this.idPayment,
    this.emailAddress,
    this.money,
    this.vat,
    this.merchantName,
    this.qrCode,
    this.qrRawData,
    this.reference,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// The URL of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrCode;

  /// The raw string / payload encoded within the QR code to be used for the Copy and Paste functionality or rendered as a QR code. Always present per spec.
  final String? qrRawData;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'MOMOPAY';

  factory MomoPayResponse.fromJson(Map<String, Object?> json) => MomoPayResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    emailAddress: json['emailAddress'] as String?,
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    qrCode: json['qrCode'] as String?,
    qrRawData: json['qrRawData'] as String?,
    reference: json['reference'] as String?,
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class NedbankDirectEFTResponse extends PaymentMethodResponse {
  const NedbankDirectEFTResponse({
    this.idPayin,
    this.idPayment,
    this.accountCustomer,
    this.money,
    this.vat,
    this.merchantName,
    this.said,
    this.emailAddress,
    this.reference,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from. Always present per spec.
  final AccountResponse? accountCustomer;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// min 13, max 13, pattern `^[0-9]*$`. Always present per spec.
  final String? said;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'NEDBANK_DIRECT_EFT';

  factory NedbankDirectEFTResponse.fromJson(Map<String, Object?> json) => NedbankDirectEFTResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    accountCustomer: _obj(json['accountCustomer'], AccountResponse.fromJson),
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    said: json['said'] as String?,
    emailAddress: json['emailAddress'] as String?,
    reference: json['reference'] as String?,
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class NetBankingResponse extends PaymentMethodResponse {
  const NetBankingResponse({
    this.idPayin,
    this.idPayment,
    this.money,
    this.vat,
    this.merchantName,
    this.reference,
    this.returnUrl,
    this.upiId,
    this.deepLink,
    this.paymentOperator,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Virtual payment address where we expect that your customer sends funds to make a payment. max 100, pattern `[a-zA-Z0-9_\-\.]+@[a-zA-Z0-9_\.]+`.
  final String? upiId;

  /// It can be used as deep link button target (what is typically known as an intent trigger) or to generate a QR code that can be scanned with any UPI enabled app.
  final String? deepLink;

  /// PaymentOperator is a financial institution that manages transactions in your customer's account (such as banks, card payment processors, mobile wallets and so on).
  final SelectedPaymentOperatorIncomingResponse? paymentOperator;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'NETBANKING';

  factory NetBankingResponse.fromJson(Map<String, Object?> json) => NetBankingResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    reference: json['reference'] as String?,
    returnUrl: json['returnUrl'] as String?,
    upiId: json['upiId'] as String?,
    deepLink: json['deepLink'] as String?,
    paymentOperator: _obj(json['paymentOperator'], SelectedPaymentOperatorIncomingResponse.fromJson),
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

/// The account parameters for this payment method are used to show payment instructions to the customer.
final class OfflineResponse extends PaymentMethodResponse {
  const OfflineResponse({
    this.idPayin,
    this.idPayment,
    this.account,
    this.accountCustomer,
    this.money,
    this.moneyRequired,
    this.vat,
    this.reference,
    this.processor,
    this.qrName,
    this.qrCode,
    this.returnUrl,
    this.paymentOperator,
    this.phoneNumber,
    this.emailAddress,
    this.productId,
    this.taxId,
    this.taxIdCustomer,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Parameters of a bank account where we expect that your customer send funds to make a payment. Always present per spec.
  final AccountResponse? account;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from. Always present per spec.
  final AccountResponse? accountCustomer;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? moneyRequired;
  final MoneyResponse? vat;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// The external processor of the payment. one of POC, PAYSTAGE, MTPX, TPAY, LCSX, PRL.
  final String? processor;

  /// The name of the QR code image to be scanned by a wallet or payment service compatible with this payment method.
  final String? qrName;

  /// The URL of the QR code image to be scanned by a wallet or payment service compatible with this payment method.
  final String? qrCode;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// PaymentOperator is a financial institution that manages transactions in your customer's account (such as banks, card payment processors, mobile wallets and so on).
  final SelectedPaymentOperatorIncomingResponse? paymentOperator;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`.
  final String? phoneNumber;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  /// Identification of a product related to a payment order. max 30, pattern `^[A-Za-z0-9_-]+$`.
  final String? productId;

  /// Tax payer identification number of a customer. min 8, max 18.
  final String? taxId;

  /// Tax payer identification number of a customer. min 8, max 18.
  final String? taxIdCustomer;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'OFFLINE';

  factory OfflineResponse.fromJson(Map<String, Object?> json) => OfflineResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    account: _obj(json['account'], AccountResponse.fromJson),
    accountCustomer: _obj(json['accountCustomer'], AccountResponse.fromJson),
    money: _obj(json['money'], MoneyResponse.fromJson),
    moneyRequired: _obj(json['moneyRequired'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    reference: json['reference'] as String?,
    processor: json['processor'] as String?,
    qrName: json['qrName'] as String?,
    qrCode: json['qrCode'] as String?,
    returnUrl: json['returnUrl'] as String?,
    paymentOperator: _obj(json['paymentOperator'], SelectedPaymentOperatorIncomingResponse.fromJson),
    phoneNumber: json['phoneNumber'] as String?,
    emailAddress: json['emailAddress'] as String?,
    productId: json['productId'] as String?,
    taxId: json['taxId'] as String?,
    taxIdCustomer: json['taxIdCustomer'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class OnlineResponse extends PaymentMethodResponse {
  const OnlineResponse({
    this.idPayin,
    this.idPayment,
    this.account,
    this.accountCustomerUsedForPayment,
    this.money,
    this.moneyRequired,
    this.vat,
    this.reference,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Parameters of a bank account where we expect that your customer send funds to make a payment. Always present per spec.
  final AccountResponse? account;

  /// Contains information about the account used by the customer.
  final AccountResponse? accountCustomerUsedForPayment;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? moneyRequired;
  final MoneyResponse? vat;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'ONLINE';

  factory OnlineResponse.fromJson(Map<String, Object?> json) => OnlineResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    account: _obj(json['account'], AccountResponse.fromJson),
    accountCustomerUsedForPayment: _obj(json['accountCustomerUsedForPayment'], AccountResponse.fromJson),
    money: _obj(json['money'], MoneyResponse.fromJson),
    moneyRequired: _obj(json['moneyRequired'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    reference: json['reference'] as String?,
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class OttVoucherResponse extends PaymentMethodResponse {
  const OttVoucherResponse({
    this.idPayin,
    this.idPayment,
    this.money,
    this.vat,
    this.merchantName,
    this.phoneNumber,
    this.emailAddress,
    this.reference,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`. Always present per spec.
  final String? phoneNumber;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins. Always present per spec.
  final String? emailAddress;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'OTT_VOUCHER';

  factory OttVoucherResponse.fromJson(Map<String, Object?> json) => OttVoucherResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    phoneNumber: json['phoneNumber'] as String?,
    emailAddress: json['emailAddress'] as String?,
    reference: json['reference'] as String?,
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

/// The account parameters for this payment method are used to show payment instructions to the customer.
final class P2AV2Response extends PaymentMethodResponse {
  const P2AV2Response({
    this.idPayin,
    this.idPayment,
    this.account,
    this.money,
    this.vat,
    this.merchantName,
    this.paymentAddress,
    this.qrName,
    this.qrCode,
    this.reference,
    this.externalReference,
    this.returnUrl,
    this.paymentOperator,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Parameters of a bank account where we expect that your customer send funds to make a payment. Always present per spec.
  final AccountResponse? account;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// Specifies the payment address (e.g. Always present per spec.
  final PaymentAddressResponse? paymentAddress;

  /// The name of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrName;

  /// The URL of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrCode;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// External payment / transaction reference is a unique identifier assigned to a financial transaction.
  final ExternalReferenceResponse? externalReference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// PaymentOperator is a financial institution that manages transactions in your customer's account (such as banks, card payment processors, mobile wallets and so on). Always present per spec.
  final SelectedPaymentOperatorIncomingResponse? paymentOperator;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'P2A_V2';

  factory P2AV2Response.fromJson(Map<String, Object?> json) => P2AV2Response(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    account: _obj(json['account'], AccountResponse.fromJson),
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    paymentAddress: _obj(json['paymentAddress'], PaymentAddressResponse.fromJson),
    qrName: json['qrName'] as String?,
    qrCode: json['qrCode'] as String?,
    reference: json['reference'] as String?,
    externalReference: _obj(json['externalReference'], ExternalReferenceResponse.fromJson),
    returnUrl: json['returnUrl'] as String?,
    paymentOperator: _obj(json['paymentOperator'], SelectedPaymentOperatorIncomingResponse.fromJson),
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class PayShapResponse extends PaymentMethodResponse {
  const PayShapResponse({
    this.idPayin,
    this.idPayment,
    this.money,
    this.vat,
    this.merchantName,
    this.accountCustomer,
    this.phoneNumber,
    this.emailAddress,
    this.reference,
    this.returnUrl,
    this.paymentOperator,
    this.externalProvider,
    this.said,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final AccountResponse? accountCustomer;

  /// Your customer's mobile phone number, starting with 0. min 12, max 12.
  final String? phoneNumber;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// PaymentOperator is a financial institution that manages transactions in your customer's account (such as banks, card payment processors, mobile wallets and so on). Always present per spec.
  final SelectedPaymentOperatorIncomingResponse? paymentOperator;

  /// TODO:
  final ExternalProviderResponse? externalProvider;

  /// min 13, max 13, pattern `^[0-9]*$`.
  final String? said;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'PAYSHAP';

  factory PayShapResponse.fromJson(Map<String, Object?> json) => PayShapResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    accountCustomer: _obj(json['accountCustomer'], AccountResponse.fromJson),
    phoneNumber: json['phoneNumber'] as String?,
    emailAddress: json['emailAddress'] as String?,
    reference: json['reference'] as String?,
    returnUrl: json['returnUrl'] as String?,
    paymentOperator: _obj(json['paymentOperator'], SelectedPaymentOperatorIncomingResponse.fromJson),
    externalProvider: _obj(json['externalProvider'], ExternalProviderResponse.fromJson),
    said: json['said'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class PayMeResponse extends PaymentMethodResponse {
  const PayMeResponse({
    this.idPayin,
    this.idPayment,
    this.account,
    this.accountCustomer,
    this.money,
    this.moneyRequired,
    this.vat,
    this.merchantName,
    this.reference,
    this.qrName,
    this.qrCode,
    this.payMeDeepLink,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Parameters of a bank account where we expect that your customer send funds to make a payment. Always present per spec.
  final AccountResponse? account;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from. Always present per spec.
  final AccountResponse? accountCustomer;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? moneyRequired;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// The name of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrName;

  /// The URL of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrCode;

  /// It can be used as deep link button target (what is typically known as an intent trigger) or to generate a QR code that can be scanned with any UPI enabled app.
  final String? payMeDeepLink;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'PAY_ME';

  factory PayMeResponse.fromJson(Map<String, Object?> json) => PayMeResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    account: _obj(json['account'], AccountResponse.fromJson),
    accountCustomer: _obj(json['accountCustomer'], AccountResponse.fromJson),
    money: _obj(json['money'], MoneyResponse.fromJson),
    moneyRequired: _obj(json['moneyRequired'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    reference: json['reference'] as String?,
    qrName: json['qrName'] as String?,
    qrCode: json['qrCode'] as String?,
    payMeDeepLink: json['payMeDeepLink'] as String?,
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class PixQRResponse extends PaymentMethodResponse {
  const PixQRResponse({
    this.idPayin,
    this.idPayment,
    this.money,
    this.vat,
    this.merchantName,
    this.qrName,
    this.qrCode,
    this.qrRawData,
    this.accountCustomer,
    this.taxId,
    this.reference,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// The name of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrName;

  /// The URL of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrCode;

  /// The raw string / payload encoded within the QR code to be used for the Copy and Paste functionality or rendered as a QR code. Always present per spec.
  final String? qrRawData;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from. Always present per spec.
  final AccountResponse? accountCustomer;

  /// Brazilian tax payer identification number - CPF for individuals / CNPJ for businesses. min 14, max 14. Always present per spec.
  final String? taxId;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'PIXQR';

  factory PixQRResponse.fromJson(Map<String, Object?> json) => PixQRResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    qrName: json['qrName'] as String?,
    qrCode: json['qrCode'] as String?,
    qrRawData: json['qrRawData'] as String?,
    accountCustomer: _obj(json['accountCustomer'], AccountResponse.fromJson),
    taxId: json['taxId'] as String?,
    reference: json['reference'] as String?,
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class PromptPayResponse extends PaymentMethodResponse {
  const PromptPayResponse({
    this.idPayin,
    this.idPayment,
    this.accountCustomer,
    this.money,
    this.vat,
    this.moneyRequired,
    this.merchantName,
    this.reference,
    this.qrName,
    this.qrCode,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from. Always present per spec.
  final AccountResponse? accountCustomer;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;
  final MoneyResponse? moneyRequired;

  /// Always present per spec.
  final String? merchantName;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// The name of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrName;

  /// The URL of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrCode;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'PROMPTPAY';

  factory PromptPayResponse.fromJson(Map<String, Object?> json) => PromptPayResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    accountCustomer: _obj(json['accountCustomer'], AccountResponse.fromJson),
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    moneyRequired: _obj(json['moneyRequired'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    reference: json['reference'] as String?,
    qrName: json['qrName'] as String?,
    qrCode: json['qrCode'] as String?,
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class PseResponse extends PaymentMethodResponse {
  const PseResponse({
    this.idPayin,
    this.idPayment,
    this.accountCustomer,
    this.emailAddress,
    this.phoneNumber,
    this.money,
    this.vat,
    this.reference,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from. Always present per spec.
  final AccountResponse? accountCustomer;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins. Always present per spec.
  final String? emailAddress;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`. Always present per spec.
  final String? phoneNumber;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'PSE';

  factory PseResponse.fromJson(Map<String, Object?> json) => PseResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    accountCustomer: _obj(json['accountCustomer'], AccountResponse.fromJson),
    emailAddress: json['emailAddress'] as String?,
    phoneNumber: json['phoneNumber'] as String?,
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    reference: json['reference'] as String?,
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class QrisPayResponse extends PaymentMethodResponse {
  const QrisPayResponse({
    this.idPayin,
    this.idPayment,
    this.accountCustomerUsedForPayment,
    this.money,
    this.vat,
    this.merchantName,
    this.reference,
    this.qrName,
    this.qrCode,
    this.qrRawData,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Contains information about the account used by the customer.
  final AccountResponse? accountCustomerUsedForPayment;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// The name of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrName;

  /// The URL of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrCode;

  /// The raw string / payload encoded within the QR code (e.g. Always present per spec.
  final String? qrRawData;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'QRISPAY';

  factory QrisPayResponse.fromJson(Map<String, Object?> json) => QrisPayResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    accountCustomerUsedForPayment: _obj(json['accountCustomerUsedForPayment'], AccountResponse.fromJson),
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    reference: json['reference'] as String?,
    qrName: json['qrName'] as String?,
    qrCode: json['qrCode'] as String?,
    qrRawData: json['qrRawData'] as String?,
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class QrPhResponse extends PaymentMethodResponse {
  const QrPhResponse({
    this.idPayin,
    this.idPayment,
    this.account,
    this.accountCustomer,
    this.money,
    this.moneyRequired,
    this.vat,
    this.merchantName,
    this.reference,
    this.qrName,
    this.qrCode,
    this.paymentOperator,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Parameters of a bank account where we expect that your customer send funds to make a payment. Always present per spec.
  final AccountResponse? account;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from. Always present per spec.
  final AccountResponse? accountCustomer;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? moneyRequired;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// The name of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrName;

  /// The URL of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrCode;

  /// PaymentOperator is a financial institution that manages transactions in your customer's account (such as banks, card payment processors, mobile wallets and so on).
  final SelectedPaymentOperatorIncomingResponse? paymentOperator;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'QRPH';

  factory QrPhResponse.fromJson(Map<String, Object?> json) => QrPhResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    account: _obj(json['account'], AccountResponse.fromJson),
    accountCustomer: _obj(json['accountCustomer'], AccountResponse.fromJson),
    money: _obj(json['money'], MoneyResponse.fromJson),
    moneyRequired: _obj(json['moneyRequired'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    reference: json['reference'] as String?,
    qrName: json['qrName'] as String?,
    qrCode: json['qrCode'] as String?,
    paymentOperator: _obj(json['paymentOperator'], SelectedPaymentOperatorIncomingResponse.fromJson),
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class SnapScanQrResponse extends PaymentMethodResponse {
  const SnapScanQrResponse({
    this.idPayin,
    this.idPayment,
    this.money,
    this.vat,
    this.merchantName,
    this.qrCode,
    this.qrRawData,
    this.snapscanQrDeepLink,
    this.reference,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// The URL of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrCode;

  /// The raw string / payload encoded within the QR code to be used for the Copy and Paste functionality or rendered as a QR code. Always present per spec.
  final String? qrRawData;

  /// Can be used as a deep link target to launch the app directly, or to generate a QR code that can be scanned by SnapScan application. Always present per spec.
  final String? snapscanQrDeepLink;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'SNAPSCAN_QR';

  factory SnapScanQrResponse.fromJson(Map<String, Object?> json) => SnapScanQrResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    qrCode: json['qrCode'] as String?,
    qrRawData: json['qrRawData'] as String?,
    snapscanQrDeepLink: json['snapscanQrDeepLink'] as String?,
    reference: json['reference'] as String?,
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class UpiCollectResponse extends PaymentMethodResponse {
  const UpiCollectResponse({
    this.idPayin,
    this.idPayment,
    this.accountCustomer,
    this.phoneNumber,
    this.money,
    this.vat,
    this.merchantName,
    this.upiIdCustomer,
    this.reference,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final AccountResponse? accountCustomer;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`.
  final String? phoneNumber;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// Virtual payment address of the customer on UPI provided by the merchant or obtained during the processing on our platform. max 100, pattern `[a-zA-Z0-9_\-\.]+@[a-zA-Z0-9_\.]+`. Always present per spec.
  final String? upiIdCustomer;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'UPICOLLECT';

  factory UpiCollectResponse.fromJson(Map<String, Object?> json) => UpiCollectResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    accountCustomer: _obj(json['accountCustomer'], AccountResponse.fromJson),
    phoneNumber: json['phoneNumber'] as String?,
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    upiIdCustomer: json['upiIdCustomer'] as String?,
    reference: json['reference'] as String?,
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class UpiIdResponse extends PaymentMethodResponse {
  const UpiIdResponse({
    this.idPayin,
    this.idPayment,
    this.money,
    this.vat,
    this.merchantName,
    this.reference,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'UPIID';

  factory UpiIdResponse.fromJson(Map<String, Object?> json) => UpiIdResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    reference: json['reference'] as String?,
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class UpiQRResponse extends PaymentMethodResponse {
  const UpiQRResponse({
    this.idPayin,
    this.idPayment,
    this.accountCustomer,
    this.accountCustomerUsedForPayment,
    this.money,
    this.vat,
    this.merchantName,
    this.reference,
    this.externalReference,
    this.processor,
    this.qrName,
    this.qrCode,
    this.upiQrDeepLink,
    this.paymentOperator,
    this.upiId,
    this.upiIdCustomer,
    this.phoneNumber,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from.
  final AccountResponse? accountCustomer;

  /// Contains information about the account used by the customer.
  final AccountResponse? accountCustomerUsedForPayment;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// External payment / transaction reference is a unique identifier assigned to a financial transaction.
  final ExternalReferenceResponse? externalReference;

  /// The external processor of the payment. one of POC, PAYSTAGE, MTPX, TPAY, LCSX, PRL.
  final String? processor;

  /// The name of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrName;

  /// The URL of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrCode;

  /// It can be used as deep link button target (what is typically known as an intent trigger) or to generate a QR code that can be scanned with any UPI enabled app.
  final String? upiQrDeepLink;

  /// PaymentOperator is a financial institution that manages transactions in your customer's account (such as banks, card payment processors, mobile wallets and so on).
  final SelectedPaymentOperatorIncomingResponse? paymentOperator;

  /// Virtual payment address where we expect that your customer sends funds to make a payment. max 100, pattern `[a-zA-Z0-9_\-\.]+@[a-zA-Z0-9_\.]+`.
  final String? upiId;

  /// Virtual payment address of the customer on UPI provided by the merchant or obtained during the processing on our platform. max 100, pattern `[a-zA-Z0-9_\-\.]+@[a-zA-Z0-9_\.]+`.
  final String? upiIdCustomer;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`.
  final String? phoneNumber;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'UPIQR';

  factory UpiQRResponse.fromJson(Map<String, Object?> json) => UpiQRResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    accountCustomer: _obj(json['accountCustomer'], AccountResponse.fromJson),
    accountCustomerUsedForPayment: _obj(json['accountCustomerUsedForPayment'], AccountResponse.fromJson),
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    reference: json['reference'] as String?,
    externalReference: _obj(json['externalReference'], ExternalReferenceResponse.fromJson),
    processor: json['processor'] as String?,
    qrName: json['qrName'] as String?,
    qrCode: json['qrCode'] as String?,
    upiQrDeepLink: json['upiQrDeepLink'] as String?,
    paymentOperator: _obj(json['paymentOperator'], SelectedPaymentOperatorIncomingResponse.fromJson),
    upiId: json['upiId'] as String?,
    upiIdCustomer: json['upiIdCustomer'] as String?,
    phoneNumber: json['phoneNumber'] as String?,
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

/// The account parameters for this payment method are used to show payment instructions to the customer.
final class VaPayResponse extends PaymentMethodResponse {
  const VaPayResponse({
    this.idPayin,
    this.idPayment,
    this.account,
    this.accountCustomer,
    this.money,
    this.vat,
    this.reference,
    this.processor,
    this.returnUrl,
    this.paymentOperator,
    this.phoneNumber,
    this.emailAddress,
    this.paymentLocationCustomer,
    this.acceptedAt,
    this.expireAt,
    this.paymentInstructionList,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Parameters of a bank account where we expect that your customer send funds to make a payment. Always present per spec.
  final AccountResponse? account;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from. Always present per spec.
  final AccountResponse? accountCustomer;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// The external processor of the payment. one of POC, PAYSTAGE, MTPX, TPAY, LCSX, PRL.
  final String? processor;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// One of following can serve as Payment Operator:
  final SelectedPaymentOperatorIncomingResponse? paymentOperator;

  /// Your customer's mobile phone number in full international telephone number format, including country code. min 7, max 16, pattern `^\+?[0-9]+$`.
  final String? phoneNumber;

  /// Your customer's e-mail address in RFC 5322 format that is used for identification of the customer's payins.
  final String? emailAddress;

  /// Specifies location where a customer is making the payment (e.g.
  final PaymentLocation? paymentLocationCustomer;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;
  final List<PaymentInstructionResponse>? paymentInstructionList;

  @override
  String get paymentMethodCode => 'VAPAY';

  factory VaPayResponse.fromJson(Map<String, Object?> json) => VaPayResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    account: _obj(json['account'], AccountResponse.fromJson),
    accountCustomer: _obj(json['accountCustomer'], AccountResponse.fromJson),
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    reference: json['reference'] as String?,
    processor: json['processor'] as String?,
    returnUrl: json['returnUrl'] as String?,
    paymentOperator: _obj(json['paymentOperator'], SelectedPaymentOperatorIncomingResponse.fromJson),
    phoneNumber: json['phoneNumber'] as String?,
    emailAddress: json['emailAddress'] as String?,
    paymentLocationCustomer: _obj(json['paymentLocationCustomer'], PaymentLocation.fromJson),
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
    paymentInstructionList: (json['paymentInstructionList'] as List?)
        ?.map((item) => PaymentInstructionResponse.fromJson(item as Map<String, Object?>))
        .toList(),
  );
}

final class VaPayVerifResponse extends PaymentMethodResponse {
  const VaPayVerifResponse({
    this.idPayin,
    this.idPayment,
    this.account,
    this.accountCustomer,
    this.money,
    this.vat,
    this.reference,
    this.returnUrl,
    this.paymentOperator,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Parameters of a bank account where we expect that your customer send funds to make a payment. Always present per spec.
  final AccountResponse? account;

  /// Parameters of your customer's bank or wallet account which your customer sends funds from. Always present per spec.
  final AccountResponse? accountCustomer;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// PaymentOperator is a financial institution that manages transactions in your customer's account (such as banks, card payment processors, mobile wallets and so on). Always present per spec.
  final SelectedPaymentOperatorIncomingResponse? paymentOperator;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'VAPAY_VERIF';

  factory VaPayVerifResponse.fromJson(Map<String, Object?> json) => VaPayVerifResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    account: _obj(json['account'], AccountResponse.fromJson),
    accountCustomer: _obj(json['accountCustomer'], AccountResponse.fromJson),
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    reference: json['reference'] as String?,
    returnUrl: json['returnUrl'] as String?,
    paymentOperator: _obj(json['paymentOperator'], SelectedPaymentOperatorIncomingResponse.fromJson),
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class VietQRResponse extends PaymentMethodResponse {
  const VietQRResponse({
    this.idPayin,
    this.idPayment,
    this.money,
    this.vat,
    this.merchantName,
    this.reference,
    this.qrName,
    this.qrCode,
    this.paymentOperator,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// The name of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrName;

  /// The URL of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrCode;

  /// PaymentOperator is a financial institution that manages transactions in your customer's account (such as banks, card payment processors, mobile wallets and so on).
  final SelectedPaymentOperatorIncomingResponse? paymentOperator;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'VIETQR';

  factory VietQRResponse.fromJson(Map<String, Object?> json) => VietQRResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    reference: json['reference'] as String?,
    qrName: json['qrName'] as String?,
    qrCode: json['qrCode'] as String?,
    paymentOperator: _obj(json['paymentOperator'], SelectedPaymentOperatorIncomingResponse.fromJson),
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

final class ZapperQrResponse extends PaymentMethodResponse {
  const ZapperQrResponse({
    this.idPayin,
    this.idPayment,
    this.money,
    this.vat,
    this.merchantName,
    this.qrCode,
    this.qrRawData,
    this.zapperQrDeepLink,
    this.reference,
    this.returnUrl,
    this.acceptedAt,
    this.expireAt,
  });

  /// Unique Merchant Order ID provided by merchant. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayin;

  /// The Unique reference ID of the Order generated by platform. max 250, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? idPayment;

  /// Always present per spec.
  final MoneyResponse? money;
  final MoneyResponse? vat;

  /// Always present per spec.
  final String? merchantName;

  /// The URL of the QR code image to be scanned by a wallet or payment service compatible with this payment method. Always present per spec.
  final String? qrCode;

  /// The raw string / payload encoded within the QR code to be used for the Copy and Paste functionality or rendered as a QR code. Always present per spec.
  final String? qrRawData;

  /// Can be used as a deep link target to launch the app directly, or to generate a QR code that can be scanned by Zapper application. Always present per spec.
  final String? zapperQrDeepLink;

  /// Reference number of transaction. Always present per spec.
  final String? reference;

  /// This is the URL where the customers will be redirected after completing a payment. max 1000. Always present per spec.
  final String? returnUrl;

  /// Date and time when payment was accepted. date-time. Always present per spec.
  final String? acceptedAt;

  /// Date and time of payment expiration. date-time. Always present per spec.
  final String? expireAt;

  @override
  String get paymentMethodCode => 'ZAPPER_QR';

  factory ZapperQrResponse.fromJson(Map<String, Object?> json) => ZapperQrResponse(
    idPayin: json['idPayin'] as String?,
    idPayment: json['idPayment'] as String?,
    money: _obj(json['money'], MoneyResponse.fromJson),
    vat: _obj(json['vat'], MoneyResponse.fromJson),
    merchantName: json['merchantName'] as String?,
    qrCode: json['qrCode'] as String?,
    qrRawData: json['qrRawData'] as String?,
    zapperQrDeepLink: json['zapperQrDeepLink'] as String?,
    reference: json['reference'] as String?,
    returnUrl: json['returnUrl'] as String?,
    acceptedAt: json['acceptedAt'] as String?,
    expireAt: json['expireAt'] as String?,
  );
}

/// An account as SYNQT reports it: the payer's, or the one to pay into. Which fields are set depends on the method.
final class AccountResponse extends Object {
  const AccountResponse({
    this.accountName,
    this.accountNumber,
    this.accountType,
    this.bankCode,
    this.bankName,
    this.bankBranch,
    this.bankCity,
    this.bankProvince,
    this.accountIndex,
  });

  /// Name of the bank account where we expect that your customer sends funds to make a payment. Rules differ per payment method.
  final String? accountName;

  /// Number of the bank account where we expect that your customer sends funds to make a payment. Rules differ per payment method.
  final String? accountNumber;

  /// Account type of the receiving bank account e.g. Rules differ per payment method.
  final String? accountType;

  /// Bank code of the bank where we expect that your customer sends funds to make a payment. Rules differ per payment method.
  final String? bankCode;

  /// Name of the bank where we expect that your customer sends funds to make a payment. Rules differ per payment method.
  final String? bankName;

  /// Branch name of the bank where we expect that your customer sends funds to make a payment. Rules differ per payment method.
  final String? bankBranch;

  /// City of the bank where we expect that your customer sends funds to make a payment. min 1.
  final String? bankCity;

  /// Province of the bank where we expect that your customer sends funds to make a payment. min 1.
  final String? bankProvince;

  /// int32.
  final int? accountIndex;

  factory AccountResponse.fromJson(Map<String, Object?> json) => AccountResponse(
    accountName: json['accountName'] as String?,
    accountNumber: json['accountNumber'] as String?,
    accountType: json['accountType'] as String?,
    bankCode: json['bankCode'] as String?,
    bankName: json['bankName'] as String?,
    bankBranch: json['bankBranch'] as String?,
    bankCity: json['bankCity'] as String?,
    bankProvince: json['bankProvince'] as String?,
    accountIndex: json['accountIndex'] as int?,
  );
}

/// TODO: Add description
final class ExternalProviderResponse extends Object {
  const ExternalProviderResponse({this.code, this.name});

  /// min 1, max 128. Always present per spec.
  final String? code;

  /// min 1. Always present per spec.
  final String? name;

  factory ExternalProviderResponse.fromJson(Map<String, Object?> json) =>
      ExternalProviderResponse(code: json['code'] as String?, name: json['name'] as String?);
}

/// External payment / transaction reference is a unique identifier assigned to a financial transaction. Customers can usually find it in their banking service such as mobile wallets, internet banking services or bank slips.
final class ExternalReferenceResponse extends Object {
  const ExternalReferenceResponse({this.reference});

  /// min 1, max 512. Always present per spec.
  final String? reference;

  factory ExternalReferenceResponse.fromJson(Map<String, Object?> json) =>
      ExternalReferenceResponse(reference: json['reference'] as String?);
}

/// An amount in major units and its ISO 4217 currency.
final class MoneyResponse extends Object {
  const MoneyResponse({this.amount, this.currencyCode});

  /// Actual amount that end-customer should pay if `paymentMethodResponse.moneyRequired.amount` is not returned. Rules differ per payment method.
  final num? amount;

  /// For supported currencies please refer to `GET /currencies`. min 1.
  final String? currencyCode;

  factory MoneyResponse.fromJson(Map<String, Object?> json) =>
      MoneyResponse(amount: json['amount'] as num?, currencyCode: json['currencyCode'] as String?);
}

/// Specifies the payment address (e.g. in UPI payment system) where customer can send the payment using theirs wallets or others banking services.
final class PaymentAddressResponse extends Object {
  const PaymentAddressResponse({this.name, this.idAddress});

  /// The name of the payment address ID e.g. Always present per spec.
  final String? name;

  /// The payment address ID where customer can send the payment. Always present per spec.
  final String? idAddress;

  factory PaymentAddressResponse.fromJson(Map<String, Object?> json) =>
      PaymentAddressResponse(name: json['name'] as String?, idAddress: json['idAddress'] as String?);
}

/// If not empty then it specifies special instructions for different banking services your customers has to follow when entering payment in their banking service.
final class PaymentInstructionResponse extends Object {
  const PaymentInstructionResponse({this.bankingService, this.companyCode});

  /// It specifies your customer banking service to which companyCode belongs. Always present per spec.
  final String? bankingService;

  /// It informs your customers that companyCode has to be used in their banking service together with Virtual Account Number from accountNumber parameter e.g. Always present per spec.
  final String? companyCode;

  factory PaymentInstructionResponse.fromJson(Map<String, Object?> json) => PaymentInstructionResponse(
    bankingService: json['bankingService'] as String?,
    companyCode: json['companyCode'] as String?,
  );
}

final class SelectedPaymentOperatorIncomingResponse extends Object {
  const SelectedPaymentOperatorIncomingResponse({this.code, this.name});

  /// One of following can serve as Payment Operator: min 1, max 30, pattern `^[A-Za-z0-9_-]+$`. Always present per spec.
  final String? code;

  /// min 1, max 1000. Always present per spec.
  final String? name;

  factory SelectedPaymentOperatorIncomingResponse.fromJson(Map<String, Object?> json) =>
      SelectedPaymentOperatorIncomingResponse(code: json['code'] as String?, name: json['name'] as String?);
}

/// Extra step a CARD payment needs from the payer (3DS and similar).
sealed class UserInteraction {
  const UserInteraction();

  String get type;

  /// Throws when a field has an unexpected type; callers fall back to [UnknownUserInteraction].
  factory UserInteraction.fromJson(Map<String, Object?> json) => switch (json['type'] as String? ?? '') {
    'CONTENT' => ContentInteraction.fromJson(json),
    'FORM' => FormInteraction.fromJson(json),
    'OTP_REQUIRED' => OtpRequiredInteraction.fromJson(json),
    'REDIRECT' => RedirectInteraction.fromJson(json),
    final code => UnknownUserInteraction(code),
  };
}

/// A `type` this SDK version does not know yet; new values are non-breaking API changes.
final class UnknownUserInteraction extends UserInteraction {
  const UnknownUserInteraction(this.type);

  @override
  final String type;

  @override
  bool operator ==(Object other) => other is UnknownUserInteraction && other.type == type;

  @override
  int get hashCode => type.hashCode;

  @override
  String toString() => 'UnknownUserInteraction($type)';
}

final class ContentInteraction extends UserInteraction {
  const ContentInteraction({this.content});

  /// Always present per spec.
  final String? content;

  @override
  String get type => 'CONTENT';

  factory ContentInteraction.fromJson(Map<String, Object?> json) =>
      ContentInteraction(content: json['content'] as String?);
}

final class FormInteraction extends UserInteraction {
  const FormInteraction({this.content});

  /// Always present per spec.
  final String? content;

  @override
  String get type => 'FORM';

  factory FormInteraction.fromJson(Map<String, Object?> json) => FormInteraction(content: json['content'] as String?);
}

final class OtpRequiredInteraction extends UserInteraction {
  const OtpRequiredInteraction();

  @override
  String get type => 'OTP_REQUIRED';

  // ignore: avoid_unused_constructor_parameters
  factory OtpRequiredInteraction.fromJson(Map<String, Object?> json) => const OtpRequiredInteraction();
}

final class RedirectInteraction extends UserInteraction {
  const RedirectInteraction({this.url});

  /// Always present per spec.
  final String? url;

  @override
  String get type => 'REDIRECT';

  factory RedirectInteraction.fromJson(Map<String, Object?> json) => RedirectInteraction(url: json['url'] as String?);
}

T? _obj<T>(Object? value, T Function(Map<String, Object?>) read) =>
    value == null ? null : read(value as Map<String, Object?>);

void _check(bool ok, String message) {
  if (!ok) throw SynqtArgumentException(message);
}
