part of '../collection.dart';

code_builder.Constructor _fromRecordModelConstructor(String className, List<Field> schema, GeneratorContext context) {
  return code_builder.Constructor(
    (d) => d
      ..factory = true
      ..name = 'fromRecordModel'
      ..requiredParameters.add(
        code_builder.Parameter(
          (p) => p
            ..type = code_builder.refer('RecordModel', 'package:pocketbase/pocketbase.dart')
            ..name = 'recordModel',
        ),
      )
      ..lambda = true
      ..body = code_builder.InvokeExpression.newOf(
        code_builder.refer('$className.fromJson'),
        [
          code_builder.refer('$className.recordModelToJSONMap').call([code_builder.refer('recordModel')])
        ],
      ).code,
  );
}
