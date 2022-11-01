typedef FutureFunction = Future<void> Function();

class Queue {
  final List<FutureFunction> list = [];

  bool runner = false;

  Future<void> execute([bool loop = false]) async {
    if (!loop && runner) return;
    runner = true;

    if (list.isEmpty) {
      runner = false;
      return;
    }

    final FutureFunction fn = list[0];
    await fn();

    list.removeAt(0);

    await execute(true);
  }

  Future<void> add(FutureFunction fn) async {
    list.add(fn);
    await execute();
  }
}

final Queue queue = Queue();
