import 'product_memory.dart';

class ProductKnowledge {
  final Map<String, ProductMemory> memories;

  const ProductKnowledge({
    this.memories = const {},
  });

  ProductMemory? getMemory(
    String consumerId,
  ) {
    return memories[consumerId];
  }

  ProductKnowledge updateMemory({
    required String consumerId,
    required ProductMemory memory,
  }) {
    final updated = Map<String, ProductMemory>.from(memories);

    updated[consumerId] = memory;

    return ProductKnowledge(
      memories: updated,
    );
  }

  bool containsConsumer(String consumerId) {
    return memories.containsKey(consumerId);
  }

  Iterable<String> get consumers => memories.keys;

  int get totalConsumers => memories.length;
}