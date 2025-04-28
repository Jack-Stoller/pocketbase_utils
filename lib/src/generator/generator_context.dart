
import 'package:pocketbase_utils/src/schema/collection/collection.dart';

/// The context used by the generator when creating files.
class GeneratorContext {
  final Map<String, String> _idToCollectionName;
  final bool _generateRelationExpansions;

  get generateRelationExpansions => _generateRelationExpansions;

  GeneratorContext(List<Collection> collections, bool generateRelationExpansions)
      : _generateRelationExpansions = generateRelationExpansions,
        _idToCollectionName = {
          for (var collection in collections)
            collection.id: collection.name,
        };

  /// Resolves a collection ID to its corresponding class name.
  String resolveCollectionName(String collectionId) {
    if (!_idToCollectionName.containsKey(collectionId)) {
      throw Exception('GeneratorContext: Collection ID "$collectionId" not found.');
    }
    return _idToCollectionName[collectionId]!;
  }
}
