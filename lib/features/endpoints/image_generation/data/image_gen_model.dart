class ImageGenRequest {
  final String prompt;
  final String userId;
  final String? negativePrompt;
  final int width;
  final int height;

  ImageGenRequest({
    required this.prompt,
    required this.userId,
    this.negativePrompt,
    this.width = 1024,
    this.height = 1024,
  });

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        'user_id': userId,
        if (negativePrompt != null) 'negative_prompt': negativePrompt,
        'width': width,
        'height': height,
      };
}

class ImageGenResponse {
  final String secureUrl;
  final String publicId;

  ImageGenResponse.fromJson(Map<String, dynamic> j)
      : secureUrl = j['secure_url'],
        publicId = j['public_id'];
}