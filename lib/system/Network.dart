import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gwcl/helpers/Constants.dart';
import 'package:gwcl/helpers/Endpoints.dart';
import 'package:gwcl/templates/Dialogs.dart';
import 'package:path/path.dart';

class NetworkUtil {
  // next three lines makes this class a Singleton
  static NetworkUtil _instance = new NetworkUtil.internal();
  NetworkUtil.internal();
  factory NetworkUtil() => _instance;

  final JsonDecoder _decoder = new JsonDecoder();
  final JsonEncoder _encoder = new JsonEncoder();

// new Dio with a Options instance.
  BaseOptions options = new BaseOptions(
    baseUrl: Endpoints.baseUrl,
    connectTimeout: 50000,
    receiveTimeout: 50000,
    sendTimeout: 50000,
    responseType: ResponseType.plain,
  );

  getMessage(dynamic response) {
    if (response is String) {
      return _encoder.convert(response.toString());
    } else {
      return response;
    }
  }

  _respond(dynamic response) {
    return '{"${Constants.success}":true,"${Constants.response}": $response,'
        '"${Constants.message}":"${Constants.success}"}';
  }

  _reject(dynamic response, dynamic message) {
    dynamic msg = getMessage(message);
    if (message.toString().contains('html')) {
      msg = getMessage(Constants.unableToReachServers);
    }
    return '{"${Constants.success}":false,"${Constants.response}": "$response",'
        '"${Constants.message}":$msg}';
  }

  Map<String, dynamic> _headers(String authToken, String appVersion) {
    return {
      'Content-type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $authToken',
      'AppVersion': '$appVersion',
    };
  }

  Future<dynamic> get(String url, String authToken, BuildContext context,
      {required Map<String, dynamic>? queryParams,
      Map? headers,
      required String appVersion}) async {
    dynamic serverResponse, response;
    try {
      Dio dio = new Dio(options);
      dio.options.headers = _headers(authToken, appVersion);

      // TODO: COMMENT OUT IN PRODUCTION
      // (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
      //     (client) {
      //   SecurityContext sc = new SecurityContext();
      //   HttpClient httpClient = new HttpClient(context: sc);
      //   // Allow all certificates
      //   httpClient.badCertificateCallback =
      //       (X509Certificate cert, String host, int port) => true;
      //   return httpClient;
      // };

      serverResponse = await dio.get(url, queryParameters: queryParams);

      if (serverResponse.statusCode < 200 || serverResponse.statusCode > 400) {
        return _decoder.convert(_reject(serverResponse.statusCode,
            serverResponse.data ?? Constants.errorEncountered));
      }
      response = _decoder.convert(_respond(serverResponse.data));
    } on DioError catch (e) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx and is also not 304.
      if (e.response != null) {
        if (e.response?.statusCode == 401) {
          showSessionExpiredDialog(context);
        }
        response = _decoder.convert(_reject(e.response?.statusCode.toString(),
            e.response?.data ?? Constants.connectionTimedOut));
      } else {
        // Something happened in setting up or sending
        // the request that triggered an Error
        response = _decoder.convert(
            _reject(Constants.appErrorCode, Constants.somethingWentWrong));
      }
    } catch (error) {
      debugPrint(error.toString());
      return _decoder.convert(
          _reject(Constants.appErrorCode, Constants.unableToSendRequest));
    }
    return response;
  }

  Future<dynamic> post(String url, String authToken, BuildContext context,
      {required Map body, Map? headers, required String appVersion}) async {
    dynamic serverResponse, response;

    try {
      Dio dio = new Dio(options);
      dio.options.headers = _headers(authToken, appVersion);

      serverResponse = await dio.post(url, data: jsonEncode(body));

      if (serverResponse.statusCode < 200 || serverResponse.statusCode > 400) {
        return _decoder.convert(_reject(serverResponse.statusCode,
            serverResponse.data ?? Constants.errorEncountered));
      }
      response = _decoder.convert(_respond(serverResponse.data));
    } on DioError catch (e) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx and is also not 304.
      if (e.response != null) {
        if (e.response?.statusCode == 401) {
          showSessionExpiredDialog(context);
        }
        response = _decoder.convert(_reject(e.response?.statusCode.toString(),
            e.response?.data ?? Constants.connectionTimedOut));
      } else {
        // Something happened in setting up or sending
        // the request that triggered an Error
        response = _decoder.convert(
            _reject(Constants.appErrorCode, Constants.somethingWentWrong));
      }
    } catch (error) {
      debugPrint(error.toString());
      return _decoder.convert(
          _reject(Constants.appErrorCode, Constants.unableToSendRequest));
    }
    return response;
  }

  Future<dynamic> upload(String url, String authToken, BuildContext context,
      {required Map body,
      required List<File> files,
      Map? headers,
      required String appVersion}) async {
    dynamic serverResponse, response;
    List<MultipartFile> uploadFiles = new List.empty(growable: true);
    try {
      Dio dio = new Dio(options);
      dio.options.headers = _headers(authToken, appVersion);

      FormData requestData;
      // add files to uploadFiles array
      if (files.length > 0) {
        for (var index = 0; index < files.length; index++) {
          MultipartFile file = MultipartFile.fromFileSync(files[index].path,
              filename: basename(files[index].path));
          uploadFiles.add(file);
        }
        requestData = new FormData.fromMap({"file[]": uploadFiles});
      } else {
        requestData = new FormData();
      }

      body.forEach((key, value) {
        MapEntry<String, String> data = new MapEntry(key, value);
        requestData.fields.add(data);
      });

      serverResponse = await dio.post(url, data: requestData);

      if (serverResponse.statusCode < 200 || serverResponse.statusCode > 400) {
        return _decoder.convert(_reject(serverResponse.statusCode,
            serverResponse.data ?? Constants.errorEncountered));
      }
      response = _decoder.convert(_respond(serverResponse.data));
    } on DioError catch (e) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx and is also not 304.
      if (e.response != null) {
        if (e.response?.statusCode == 401) {
          showSessionExpiredDialog(context);
        }
        response = _decoder.convert(_reject(e.response?.statusCode.toString(),
            e.response?.data ?? Constants.connectionTimedOut));
      } else {
        // Something happened in setting up or
        // sending the request that triggered an Error
        response = _decoder.convert(
            _reject(Constants.appErrorCode, Constants.somethingWentWrong));
      }
    } catch (error) {
      debugPrint(error.toString());
      return _decoder.convert(
          _reject(Constants.appErrorCode, Constants.unableToSendRequest));
    }
    return response;
  }
}
