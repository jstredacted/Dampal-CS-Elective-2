import 'package:supabase_flutter/supabase_flutter.dart';

// Turns an error from Supabase into a sentence the user can understand.
String friendlyError(Object error) {
  if (error is PostgrestException) {
    // 42501 is Postgres' "insufficient privilege" code. Row Level Security
    // and the place_order function both use it to refuse an action.
    if (error.code == '42501') {
      return 'You do not have permission to do that.';
    }
    // 23503 means another row still points to this one (a foreign key).
    if (error.code == '23503') {
      return 'This item is still being used by other records.';
    }
    return error.message;
  }
  if (error is AuthException) return error.message;
  if (error is StorageException) return error.message;
  return error.toString().replaceFirst('Exception: ', '');
}

bool isPermissionDenied(Object error) =>
    error is PostgrestException && error.code == '42501';
