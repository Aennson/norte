import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:norte/application/usecases/delete_task.dart';
import 'package:norte/domain/failures/failure.dart';
import 'package:norte/domain/failures/result.dart';
import 'package:norte/domain/ports/task_repository.dart';

class _MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  late _MockTaskRepository repository;
  late DeleteTask deleteTask;

  setUp(() {
    repository = _MockTaskRepository();
    deleteTask = DeleteTask(repository: repository);
    when(() => repository.delete(any())).thenAnswer((_) async {});
  });

  test('S01-UT-01: deleting forwards the id to the repository once', () async {
    final Result<void> result = await deleteTask('task-1');

    expect(result, isA<Ok<void>>());
    verify(() => repository.delete('task-1')).called(1);
  });

  test(
    'S01-UT-02: a blank id is rejected without touching the repository',
    () async {
      final Result<void> result = await deleteTask('  ');

      expect((result as Err<void>).failure, isA<ValidationFailure>());
      verifyNever(() => repository.delete(any()));
    },
  );

  test(
    'S01-UT-01: deleting twice is not an error at the use-case level',
    () async {
      expect(await deleteTask('task-1'), isA<Ok<void>>());
      expect(await deleteTask('task-1'), isA<Ok<void>>());

      verify(() => repository.delete('task-1')).called(2);
    },
  );
}
