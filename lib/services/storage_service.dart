import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String productImagesBucket = 'product-images';

class StorageService {
  StorageService(this._client);

  final SupabaseClient _client;

  // Uploads the picked image to Supabase Storage and returns its public link,
  // which is what gets saved in products.image_url.
  Future<String> uploadProductImage(Uint8List bytes, String fileName) async {
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    // A timestamp keeps every file name unique.
    final path = 'products/${DateTime.now().millisecondsSinceEpoch}.$extension';
    final bucket = _client.storage.from(productImagesBucket);
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: 'image/${extension == 'jpg' ? 'jpeg' : extension}',
      ),
    );
    return bucket.getPublicUrl(path);
  }
}
