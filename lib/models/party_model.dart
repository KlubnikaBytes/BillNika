class PartyModel {
  final int id;
  final String partyName;
  final String? contactNumber;
  final String partyType;

  // GST / PAN
  final String? gstNumber;
  final String? panNumber;

  // Opening balance
  final double openingBalance;
  final String openingBalanceType;

  // Credit
  final int? creditPeriodDays;
  final double? creditLimit;

  // Other
  final String? contactPersonName;
  final DateTime? dob;

  // Billing address
  final String? billingStreet;
  final String? billingCity;
  final String? billingState;
  final String? billingPincode;

  PartyModel({
    required this.id,
    required this.partyName,
    this.contactNumber,
    required this.partyType,
    required this.openingBalance,
    required this.openingBalanceType,

    // new (optional – won’t break create)
    this.gstNumber,
    this.panNumber,
    this.creditPeriodDays,
    this.creditLimit,
    this.contactPersonName,
    this.dob,
    this.billingStreet,
    this.billingCity,
    this.billingState,
    this.billingPincode,
  });

  factory PartyModel.fromJson(Map<String, dynamic> json) {
    return PartyModel(
      id: json['id'],
      partyName: json['party_name'],
      contactNumber: json['contact_number'],
      partyType: json['party_type'] ?? 'customer',

      openingBalance:
      json['opening_balance'] != null
          ? double.tryParse(json['opening_balance'].toString()) ?? 0
          : 0,

      // ✅ default = receive
      openingBalanceType: json['opening_balance_type'] ?? 'receive',

      // GST / PAN
      gstNumber: json['gst_number'],
      panNumber: json['pan_number'],

      // Credit
      creditPeriodDays: json['credit_period_days'],
      creditLimit: json['credit_limit'] != null
          ? double.tryParse(json['credit_limit'].toString())
          : null,

      // Other
      contactPersonName: json['contact_person_name'],
      dob: json['dob'] != null ? DateTime.tryParse(json['dob']) : null,

      // Billing
      billingStreet: json['billing_street'],
      billingCity: json['billing_city'],
      billingState: json['billing_state'],
      billingPincode: json['billing_pincode'],
    );
  }
}
