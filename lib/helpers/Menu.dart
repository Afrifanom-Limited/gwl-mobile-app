import 'package:gwcl/helpers/Constants.dart';

class Menu {
  static const paymentMethod = [
    {
      "display": "Mtn Mobile Money",
      "value": "MTN",
      "image": Constants.kMomoIcon,
    },
    {
      "display": "Vodafone Cash",
      "value": "VODAFONE",
      "image": Constants.kVodafoneIcon
    },
    {
      "display": "AirtelTigo Money",
      "value": "AIRTELTIGO",
      "image": Constants.kAirteltigoIcon
    },
    {"display": "Debit Card", "value": "CARD", "image": Constants.kVisaIcon},
  ];

  static const complaintType = [
    {"value": "over-billing", "display": "Over-billing"},
    {"value": "unreflected payment", "display": "Unreflected payment"},
    {"value": "pipe burst", "display": "Pipe burst"},
    {"value": "leakage", "display": "Pipe leakage"},
    {"value": "no flow", "display": "No flow"},
    {"value": "low pressure", "display": "Low pressure"},
    {"value": "quality of water", "display": "Quality of water"},
    {"value": "incorrect meter reading", "display": "Incorrect meter reading"},
    {"value": "faulty meter", "display": "Faulty meter"},
    {"value": "stolen meters", "display": "Stolen meters"},
    {"value": "illegal connection", "display": "Illegal connection"},
    {"value": "wrong disconnection", "display": "Wrong disconnection"},
    {"value": "enquiry", "display": "Enquiry"},
    {"value": "other", "display": "Other (Please specify in message)"},
  ];

  static const reportType = [
    {
      "display": "Statement of Billing",
      "value": "billing",
    },
    {
      "display": "Statement of Payment",
      "value": "statement",
    },
  ];

  static const billingReportType = [
    {
      "display": "Single Month",
      "value": "single",
    },
    {
      "display": "Date Range",
      "value": "multiple",
    },
  ];

  static const banks = [
    {
      "display": "Access Bank",
      "value": "ACCESSBANK",
    },
    {
      "display": "ADB Bank",
      "value": "ADB",
    },
    {
      "display": "ARB Apex Bank",
      "value": "ARBAPEX",
    },
    {
      "display": "Bank of Africa",
      "value": "BOA",
    },
    {
      "display": "Bank of Ghana",
      "value": "BOG",
    },
    {
      "display": "Barclays Bank",
      "value": "BARCLAYS",
    },
    {
      "display": "CAL Bank",
      "value": "CALBANK",
    },
    {
      "display": "Ecobank",
      "value": "ECOBANK",
    },
    {
      "display": "Energy Bank",
      "value": "ENERGYBANK",
    },
    {
      "display": "FBN Bank",
      "value": "FBN",
    },
    {
      "display": "Fidelity Bank",
      "value": "FIDELITY",
    },
    {
      "display": "First Atlantic Bank",
      "value": "FIRSTATLAN",
    },
    {
      "display": "First National Bank",
      "value": "FIRSTNAT",
    },
    {
      "display": "GCB Bank",
      "value": "GCB",
    },
    {
      "display": "GHL Bank",
      "value": "GHLBANK",
    },
    {
      "display": "Guaranty Trust Bank",
      "value": "GTBANK",
    },
    {
      "display": "National Investment Bank",
      "value": "NIB",
    },
    {
      "display": "OmniBSIC Bank",
      "value": "OMNIBSIC",
    },
    {
      "display": "Prudential Bank",
      "value": "PRUDENTIAL",
    },
    {
      "display": "Republic Bank",
      "value": "REPUBLIC",
    },
    {
      "display": "Societe Generale",
      "value": "SOCIETEGEN",
    },
    {
      "display": "Stanbic Bank",
      "value": "STANBIC",
    },
    {
      "display": "StanChart Bank",
      "value": "STANCHART",
    },
    {
      "display": "UBA",
      "value": "UBA",
    },
    {
      "display": "UMB",
      "value": "UMB",
    },
    {
      "display": "Zenith Bank",
      "value": "ZENITH",
    },
  ];
}
