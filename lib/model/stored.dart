/// An interface for the types that can be stored
abstract class StoredObject {
  /// [returns] the serialized version of the object for the SharedPreferences
  String toStorage();
}

/// An interface for the types that can be send to the smartwatch
abstract class SharedObject {
  /// [returns] the serialized version of the object for the smartwatch
  String serialize();
}
