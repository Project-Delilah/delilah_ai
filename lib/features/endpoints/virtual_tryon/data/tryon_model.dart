import 'dart:io';

class TryOnRequest {
  final File personImage;
  final File garmentImage;
  final String userId;

  TryOnRequest({
    required this.personImage,
    required this.garmentImage,
    required this.userId,
  });
}

class TryOnResponse {
  final String secureUrl;

  TryOnResponse.fromJson(Map<String, dynamic> j) : secureUrl = j['secure_url'];
}