import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'rov_api_client.g.dart';

@RestApi()
abstract class RovApiClient {
  factory RovApiClient(Dio dio, {String? baseUrl}) = _RovApiClient;

  @GET('/health')
  Future<HttpResponse<dynamic>> health();

  @GET('/status')
  Future<HttpResponse<dynamic>> status();

  @GET('/sonar')
  Future<HttpResponse<dynamic>> sonar();

  @GET('/environment')
  Future<HttpResponse<dynamic>> environment();

  @POST('/mode')
  Future<HttpResponse<dynamic>> setMode(@Body() Map<String, dynamic> body);

  @POST('/control')
  Future<HttpResponse<dynamic>> control(@Body() Map<String, dynamic> body);

  @POST('/emergency-stop')
  Future<HttpResponse<dynamic>> emergencyStop();

  @POST('/emergency-clear')
  Future<HttpResponse<dynamic>> clearEmergency();
}
