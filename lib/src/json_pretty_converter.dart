import 'dart:convert';

import 'package:dio/dio.dart';

class JsonPrettyConverter {
  static JsonPrettyConverter? _instance;

  factory JsonPrettyConverter() =>
      _instance ??= JsonPrettyConverter._internal();
  JsonPrettyConverter._internal() {
    _encoder = const JsonEncoder.withIndent('  ');
  }

  static late final JsonEncoder _encoder;

  String convert(text) {
    text = x;
    late final String prettyprint;
    if (text is Map || text is String || text is List)
      prettyprint = _convertToPrettyJsonFromMapOrJson(text);
    else if (text is FormData)
      prettyprint = 'FormData:\n${_convertToPrettyFromFormData(text)}';
    else if (text == null)
      prettyprint = '';
    else
      prettyprint = text.toString();
    return prettyprint;
  }

  String _convertToPrettyFromFormData(FormData text) {
    final map = {
      for (final e in text.fields) e.key: e.value,
      for (final e in text.files) e.key: e.value.filename
    };

    return _convertToPrettyJsonFromMapOrJson(map);
  }

  String _convertToPrettyJsonFromMapOrJson(text) {
    if (text is! Map) return _encoder.convert(text);

    text = {
      for (final e in text.entries)
        if (e.value is Map || e.value is List || e.value is String)
          e.key: e.value
        else
          e.key: convert(e.value)
    };
    return _encoder.convert(text);
  }

  dynamic deconvertFrom(String text, String? oldDataType) {
    if (oldDataType == null) return null;

    oldDataType = _removeUnderScoreIfExists(oldDataType);
    try {
      if (oldDataType.contains('Map')) return jsonDecode(text);
      if (oldDataType.startsWith('String')) return text;
      if (oldDataType.startsWith('List')) return jsonDecode(text);

      return null;
    } catch (e) {
      return null;
    }
  }

  String _removeUnderScoreIfExists(String dataTypeName) =>
      dataTypeName.replaceFirst('_', '');
}

dynamic x = {
  "Data": {
    "scrNm": "تحضير الأصناف",
    "scrTyp": 3,
    "inactvFlg": 0,
    "rprtNo": 4171,
    "grpNoRprt": 1626,
    "master": [
      {
        "tpNm": "tp_main_data",
        "tpTxt": "البيانات الرئيسية",
        "groups": [
          {
            "groupId": "g_mst_data",
            "isFlds": true,
            "groupNm": null,
            "flds": [
              {
                "fldNm": "yr_no",
                "fldTxt": "السنة",
                "dbFlg": 1,
                "mndtryFlg": true,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_MST",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "unt_no",
                "fldTxt": "الوحدة المالية",
                "dbFlg": 1,
                "mndtryFlg": true,
                "hdFlg": false,
                "fldTyp": 3,
                "flgLstTyp": 2,
                "flgCode": "LST_FN_UNT_EFCT",
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_MST",
                "fldNmPrmtr": null,
                "lovNm": "LOV_FN_UNT_EFCT",
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "typ_no",
                "fldTxt": "نوع الوثيقة الفرعي",
                "dbFlg": 1,
                "mndtryFlg": true,
                "hdFlg": false,
                "fldTyp": 3,
                "flgLstTyp": 2,
                "flgCode": "LST_DOC_TYP_DTL",
                "flgLstWhr": "AND DOC_TYP = 937",
                "objNm": "INV_PRPRTN_ITM_MST",
                "fldNmPrmtr": null,
                "lovNm": "LOV_GNR_DOC_TYP_DTL",
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "doc_no",
                "fldTxt": "رقم الوثيقة",
                "dbFlg": 1,
                "mndtryFlg": true,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_MST",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "doc_date",
                "fldTxt": "تاريخ الوثيقة",
                "dbFlg": 1,
                "mndtryFlg": true,
                "hdFlg": false,
                "fldTyp": 10,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_MST",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "w_code",
                "fldTxt": "رقم المخزن",
                "dbFlg": 1,
                "mndtryFlg": true,
                "hdFlg": false,
                "fldTyp": 3,
                "flgLstTyp": 2,
                "flgCode": "LST_WCODE",
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_MST",
                "fldNmPrmtr": null,
                "lovNm": "LOV_WC",
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "doc_typ_sub",
                "fldTxt": "إنزال من",
                "dbFlg": 1,
                "mndtryFlg": true,
                "hdFlg": false,
                "fldTyp": 3,
                "flgLstTyp": 2,
                "flgCode": "LST_ITM_PRPRTN",
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_MST",
                "fldNmPrmtr": null,
                "lovNm": "LOV_INV_ITM_PRPRTN",
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "doc_typ_ref",
                "fldTxt": "نوع الوثيقة المرجعية",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 3,
                "flgLstTyp": 2,
                "flgCode": "LST_LOV_S_DOC_TYP_SYS",
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_MST",
                "fldNmPrmtr": null,
                "lovNm": "LOV_S_DOC_TYP_SYS",
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "prpr_typ",
                "fldTxt": "سياسة التحضير",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 3,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_MST",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "doc_no_ref",
                "fldTxt": "رقم الوثيقة المرجعية",
                "dbFlg": 1,
                "mndtryFlg": true,
                "hdFlg": false,
                "fldTyp": 3,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_MST",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "dmy_doc_date_ref",
                "fldTxt": "تاريخ الوثيقة المرجعية",
                "dbFlg": 0,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 10,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_MST",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "doc_dsc",
                "fldTxt": "البيان",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 8,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_MST",
                "fldNmPrmtr": null,
                "lovNm": "LOV_DOC_DSC",
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "chk_qty_flg",
                "fldTxt": "فحص الكميات",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 6,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_MST",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              }
            ]
          }
        ]
      },
      {
        "tpNm": "tp_othr_data",
        "tpTxt": "بيانات أخرى",
        "groups": [
          {
            "groupId": "g_othr_data",
            "isFlds": true,
            "groupNm": null,
            "flds": [
              {
                "fldNm": "ref_no",
                "fldTxt": "رقم المرجع",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 1,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_MST",
                "fldNmPrmtr": null,
                "lovNm": "LOV_DOC_REF",
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "mnl_no",
                "fldTxt": "الرقم اليدوي",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 1,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_MST",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              }
            ]
          }
        ]
      },
      {
        "tpNm": "tp_add_fld",
        "tpTxt": "حقول إضافية",
        "groups": [
          {
            "groupId": "g_add_fld",
            "isFlds": true,
            "groupNm": null,
            "flds": []
          }
        ]
      }
    ],
    "detail": [
      {
        "tpNm": "tp_dtl",
        "groups": [
          {
            "groupId": "g_dtl",
            "isFlds": false,
            "groupNm": null,
            "flds": [
              {
                "fldNm": "itm_code",
                "fldTxt": "رقم الصنف",
                "dbFlg": 1,
                "mndtryFlg": true,
                "hdFlg": false,
                "fldTyp": 3,
                "flgLstTyp": 2,
                "flgCode": "LST_ITM_CODE",
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_DTL",
                "fldNmPrmtr": null,
                "lovNm": "LOV_ITM_CODE",
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "itm_unt",
                "fldTxt": "وحدة القياس",
                "dbFlg": 1,
                "mndtryFlg": true,
                "hdFlg": false,
                "fldTyp": 3,
                "flgLstTyp": 2,
                "flgCode": "LST_ITM_UNT",
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_DTL",
                "fldNmPrmtr": null,
                "lovNm": "LOV_ITM_UNT",
                "lovWhr": null,
                "flgItmDpndFrnt": [
                  {
                    "flgVal": "itm_code",
                    "flgNm": "رقم الصنف"
                  }
                ]
              },
              {
                "fldNm": "itm_unt_cnt",
                "fldTxt": "الوحدة العددية",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 3,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_DTL",
                "fldNmPrmtr": null,
                "lovNm": "LOV_CNT_UNT",
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "argmnt_no",
                "fldTxt": "قيمة المعامل",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 1,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_DTL",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "exp_date",
                "fldTxt": "تاريخ الإنتهاء",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 3,
                "flgLstTyp": 2,
                "flgCode": "LST_EXP_DATE_AVLQTY",
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_DTL",
                "fldNmPrmtr": null,
                "lovNm": "LOV_INV_EXP_DATE",
                "lovWhr": null,
                "flgItmDpndFrnt": [
                  {
                    "flgVal": "itm_code",
                    "flgNm": "رقم الصنف"
                  },
                  {
                    "flgVal": "w_code",
                    "flgNm": "رقم المخزن"
                  }
                ]
              },
              {
                "fldNm": "itm_sgmnt_cntct",
                "fldTxt": "المقطع التحليلي",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 3,
                "flgLstTyp": 2,
                "flgCode": "LST_ITM_SGMNT_CNTCT",
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_DTL",
                "fldNmPrmtr": null,
                "lovNm": "LOV_INV_ITM_SGMNT_CNTCT",
                "lovWhr": null,
                "flgItmDpndFrnt": [
                  {
                    "flgVal": "itm_code",
                    "flgNm": "رقم الصنف"
                  },
                  {
                    "flgVal": "w_code",
                    "flgNm": "رقم المخزن"
                  }
                ]
              },
              {
                "fldNm": "itm_lngth",
                "fldTxt": "الطول",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 1,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_DTL",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "itm_wdth",
                "fldTxt": "العرض",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 1,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_DTL",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "itm_hght",
                "fldTxt": "الإرتفاع",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 1,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_DTL",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "itm_cnt",
                "fldTxt": "العدد",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 1,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_DTL",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "itm_qty_cnt",
                "fldTxt": "الكمية العددية",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 1,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_DTL",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "shlf_code",
                "fldTxt": "رقم الموقع",
                "dbFlg": 1,
                "mndtryFlg": true,
                "hdFlg": false,
                "fldTyp": 3,
                "flgLstTyp": 2,
                "flgCode": "LST_SHLF",
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_DTL",
                "fldNmPrmtr": null,
                "lovNm": "LOV_SHLF",
                "lovWhr": null,
                "flgItmDpndFrnt": [
                  {
                    "flgVal": "w_code",
                    "flgNm": "رقم المخزن"
                  }
                ]
              },
              {
                "fldNm": "itm_qty",
                "fldTxt": "الكمية المحضرة",
                "dbFlg": 1,
                "mndtryFlg": true,
                "hdFlg": false,
                "fldTyp": 1,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_DTL",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "itm_barcode",
                "fldTxt": "رقم الباركود",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_DTL",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "chk_qty",
                "fldTxt": "كمية الفحص",
                "dbFlg": 0,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_DTL",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              }
            ]
          },
          {
            "groupId": "g_dtl_srl",
            "isFlds": false,
            "groupNm": null,
            "flds": [
              {
                "fldNm": "itm_srl_no",
                "fldTxt": "الرقم التسلسلي للصنف",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 1,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_SRL_TMP",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              }
            ]
          }
        ]
      }
    ],
    "dtldtl": [
      {
        "tpNm": "tp_itm_doc",
        "tpTxt": "أصناف المستند",
        "groups": [
          {
            "groupId": "g_itm_doc",
            "isFlds": false,
            "groupNm": "الأصناف",
            "flds": [
              {
                "fldNm": "itm_code",
                "fldTxt": "رقم الصنف",
                "dbFlg": 1,
                "mndtryFlg": true,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "itm_unt",
                "fldTxt": "وحدة القياس",
                "dbFlg": 1,
                "mndtryFlg": true,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "itm_unt_cnt",
                "fldTxt": "الوحدة العددية",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": "LOV_CNT_UNT",
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "argmnt_no",
                "fldTxt": "قيمة المعامل",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "exp_date",
                "fldTxt": "تاريخ الإنتهاء",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "itm_sgmnt_cntct",
                "fldTxt": "المقطع التحليلي",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "itm_lngth",
                "fldTxt": "الطول",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "itm_wdth",
                "fldTxt": "العرض",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "itm_hght",
                "fldTxt": "الإرتفاع",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "itm_cnt",
                "fldTxt": "العدد",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "itm_qty_cnt",
                "fldTxt": "الكمية العددية",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "itm_qty",
                "fldTxt": "الكمية",
                "dbFlg": 1,
                "mndtryFlg": true,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "prpr_qty",
                "fldTxt": "الكمية المحضرة",
                "dbFlg": 0,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "mn_prpr_qty",
                "fldTxt": "ك.أقل مكون",
                "dbFlg": 0,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "rem_qty",
                "fldTxt": "الكمية المتبقية",
                "dbFlg": 0,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPRTN_ITM_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              }
            ]
          }
        ]
      },
      {
        "tpNm": "tp_itm_cmpnnt",
        "tpTxt": "مكونات الأصناف",
        "groups": [
          {
            "groupId": "g_itm_cmpnnt",
            "isFlds": false,
            "groupNm": "الأصناف",
            "flds": [
              {
                "fldNm": "itm_code",
                "fldTxt": "رقم الصنف",
                "dbFlg": 1,
                "mndtryFlg": true,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPR_ITM_CMPNNT_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "itm_unt",
                "fldTxt": "وحدة القياس",
                "dbFlg": 1,
                "mndtryFlg": true,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPR_ITM_CMPNNT_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "exp_date",
                "fldTxt": "تاريخ الإنتهاء",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPR_ITM_CMPNNT_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "itm_sgmnt_cntct",
                "fldTxt": "المقطع التحليلي",
                "dbFlg": 1,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPR_ITM_CMPNNT_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "itm_qty",
                "fldTxt": "الكمية",
                "dbFlg": 1,
                "mndtryFlg": true,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPR_ITM_CMPNNT_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "prpr_qty",
                "fldTxt": "الكمية المحضرة",
                "dbFlg": 0,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPR_ITM_CMPNNT_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              },
              {
                "fldNm": "rem_qty",
                "fldTxt": "الكمية المتبقية",
                "dbFlg": 0,
                "mndtryFlg": false,
                "hdFlg": false,
                "fldTyp": 0,
                "flgLstTyp": null,
                "flgCode": null,
                "flgLstWhr": null,
                "objNm": "INV_PRPR_ITM_CMPNNT_QRY_PRC",
                "fldNmPrmtr": null,
                "lovNm": null,
                "lovWhr": null,
                "flgItmDpndFrnt": []
              }
            ]
          }
        ]
      }
    ],
    "const": [],
    "ddcTotlLst": [
      {
        "fldNm": "srl_cnt",
        "fldTxt": "عدد الأرقام التسلسلية",
        "dbFlg": 0,
        "mndtryFlg": false,
        "hdFlg": false,
        "fldTyp": 0,
        "flgLstTyp": null,
        "flgCode": null,
        "flgLstWhr": null,
        "fldNmPrmtr": null,
        "lovNm": null,
        "lovWhr": null,
        "fldColor": null
      }
    ],
    "usrActnPrv": {
      "add": true,
      "add2": true,
      "upd": true,
      "del": true,
      "save": true,
      "srch": true,
      "prnt": true,
      "inactv": false,
      "apprvd": true,
      "cncl": false,
      "stndby": false,
      "vrfy": false,
      "pst": false,
      "jrnl": true,
      "scrPrmtr": true,
      "scrRprt": true,
      "arc": true,
      "audt": false,
      "import": true,
      "export": false
    },
    "usrPrvLst": {
      "ALLW_CHNG_DOC_DATE": {
        "prvVal": "1",
        "prvValNm": "1",
        "prvLbl": "السماح بتعديل تاريخ الوثيقة"
      },
      "ALLW_DELT_PRD": {
        "prvVal": null,
        "prvValNm": null,
        "prvLbl": "مدة السماح للمستخدم بحذف الوثيقة - بالدقائق"
      },
      "ALLW_PRNT_NOT_APPRVD_DOC": {
        "prvVal": "1",
        "prvValNm": "1",
        "prvLbl": "السماح بطباعة المستندات الغير معتمدة"
      },
      "ALLW_UPD_PRD": {
        "prvVal": null,
        "prvValNm": null,
        "prvLbl": "مدة السماح للمستخدم بتعديل الوثيقة - بالدقائق"
      }
    },
    "aftrSaveActn": {
      "drctAddAftrSaveflg": false,
      "drctPrntAftrSaveflg": false
    },
    "scrPrmtrLst": {
      "INV_USE_EXP_DATE": {
        "prmtrVal": "1",
        "prmtrValNm": "1",
        "prmtrLbl": "استخدام تاريخ الإنتهاء"
      },
      "INV_USE_ITM_SGMNT": {
        "prmtrVal": "1",
        "prmtrValNm": "1",
        "prmtrLbl": "استخدام مقاطع الأصناف"
      },
      "INV_USE_SRL_NO_TYP": {
        "prmtrVal": "2",
        "prmtrValNm": "2-بعد الوثيقة",
        "prmtrLbl": "طريقة استخدام الأرقام التسلسلية"
      }
    },
    "qryPrmtrLst": {}
  },
  "Result": {
    "errNo": 0,
    "errMsg": "تمت العملية بنجاح "
  }
};