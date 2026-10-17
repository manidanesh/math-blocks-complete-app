import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:number_bond_math/repositories/base_repository.dart';
import 'package:number_bond_math/services/error_handler_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channel = MethodChannel('plugins.flutter.io/shared_preferences');

class _Preferences {
  final Map<String, Object> disk = {};
  bool rejectWrites = false;
  bool throwWrites = false;

  Future<Object?> handle(MethodCall call) async {
    if (call.method == 'getAll') return Map<String, Object>.from(disk);
    if (throwWrites) throw PlatformException(code: 'storage_unavailable');
    if (rejectWrites) return false;
    final args = call.arguments as Map<Object?, Object?>;
    final key = args['key']! as String;
    if (call.method == 'remove') {
      disk.remove(key);
    } else if (call.method.startsWith('set')) {
      disk[key] = args['value']!;
    } else {
      throw StateError('Unexpected preference method: ${call.method}');
    }
    return true;
  }
}

class _Repository extends BaseRepository<String> {
  _Repository() : super('repository-test');

  @override
  String serialize(String item) => item;

  @override
  String deserialize(String json) => json;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Preferences store;
  late _Repository repository;

  setUp(() {
    SharedPreferences.resetStatic();
    store = _Preferences();
    repository = _Repository();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, store.handle);
  });
  tearDown(() {
    SharedPreferences.resetStatic();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  for (final throws in [false, true]) {
    for (final operation in ['save', 'saveList', 'delete']) {
      test(
        '${throws ? 'throwing' : 'rejected'} $operation restores readable saved data',
        () async {
          final list = operation == 'saveList';
          if (list) {
            await repository.saveList(['before']);
          } else {
            await repository.save('before');
          }
          final before = Map<String, Object>.from(store.disk);
          store.rejectWrites = !throws;
          store.throwWrites = throws;
          await expectLater(switch (operation) {
            'save' => repository.save('after'),
            'saveList' => repository.saveList(['after']),
            _ => repository.delete(),
          }, throwsA(isA<AppError>()));
          expect(store.disk, before);
          if (list) {
            expect(await repository.loadList(), ['before']);
          } else {
            expect(await repository.load(), 'before');
          }
          store.rejectWrites = false;
          store.throwWrites = false;
          if (list) {
            await repository.saveList(['after']);
            expect(await repository.loadList(), ['after']);
          } else if (operation == 'save') {
            await repository.save('after');
            expect(await repository.load(), 'after');
          } else {
            await repository.delete();
            expect(await repository.load(), isNull);
          }
        },
      );
    }
  }
}
