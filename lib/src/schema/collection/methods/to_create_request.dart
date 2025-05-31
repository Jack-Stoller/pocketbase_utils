part of '../collection.dart';

code_builder.Method _toCreateRequestMethod(String className, Iterable<Field> allFieldsExceptHidden) {
  return code_builder.Method((m) => m
    ..returns = code_builder.refer('Map<String, dynamic>')
    ..name = 'toCreateRequest'
    ..body = code_builder.Block((bb) {
      code_builder.Code addFieldToResultWithCheckCode(Field field) {
        final addFieldCode = code_builder.refer('result').property('addAll').call([
          code_builder.literalMap({
            code_builder.refer('${className}FieldsEnum.${field.nameInCamelCase}.nameInSchema'): code_builder
                .refer('jsonMap')
                .index(code_builder.refer('${className}FieldsEnum.${field.nameInCamelCase}.nameInSchema')),
          })
        ]).statement;

        if (field.required == true) {
          return addFieldCode;
        }

        return ifStatement(
          code_builder.refer(field.nameInCamelCase).notEqualTo(code_builder.literalNull),
          addFieldCode,
        );
      }

      bb.statements.addAll([
        code_builder
            .declareFinal('jsonMap')
            .assign(
              code_builder.refer('this').property('toJson').call([]),
            ).statement,
        code_builder
            .declareFinal('result', type: code_builder.refer('Map<String, dynamic>'))
            .assign(code_builder.literalMap({}))
            .statement,
        for (final field in allFieldsExceptHidden.where((f) => !baseFields.contains(f)))
          addFieldToResultWithCheckCode(field),
        code_builder.refer('result').returned.statement,
      ]);
    }));
}
