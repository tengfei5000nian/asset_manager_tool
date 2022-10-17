import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:asset_manager_tool/command.dart';

void main(List<String> arguments) async {
  try {
    final CommandRunner<int> commandRunner = CommandRunner(
      'asset_manager_tool',
      'Unified interface for running Dart builds.'
    )
      ..addCommand(WatchCommand())
      ..addCommand(BuildAssetCommand())
      ..addCommand(BuildListCommand());

    final ArgResults argResults = commandRunner.parse(arguments);
    await commandRunner.runCommand(argResults);
  } catch (err) {
    print(err);
  }
}
