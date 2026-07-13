import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'secure_token_storage.dart';
import 'token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);
