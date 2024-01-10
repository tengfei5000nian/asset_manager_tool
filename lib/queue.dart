typedef FutureFunction = Future<void> Function();

class Queue {
  final List<FutureFunction> list = [];

  bool runner = false;

  Future<void> execute([bool loop = false]) async {
    if (runner) return;
    runner = true;

    if (list.isEmpty) {
      runner = false;
      return;
    }

    await list.first();

    list.removeAt(0);

    runner = false;

    if (loop) await execute(loop);
  }

  Future<void> add(FutureFunction fn) async {
    list.add(fn);
    await execute(true);
  }
}

final Queue queue = Queue();
