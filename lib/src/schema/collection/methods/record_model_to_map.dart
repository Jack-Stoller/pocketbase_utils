part of '../collection.dart';

code_builder.Method _recordModelToMapMethod(String className, List<Field> schema, GeneratorContext context) {
  return code_builder.Method(
    (m) => m
      ..returns = code_builder.refer('dynamic')
      ..name = 'recordModelToJSONMap'
      ..static = true
      ..requiredParameters.add(
        code_builder.Parameter(
          (p) => p
            ..type = code_builder.TypeReference(
              (b) => b
                ..symbol = 'RecordModel'
                ..url = 'package:pocketbase/pocketbase.dart'
                ..isNullable = true,
            )
            ..name = 'recordModel',
        ),
      )
      ..lambda = true
      ..body = code_builder
          .refer('recordModel')
          .equalTo(code_builder.literalNull)
          .conditional(
              code_builder.literalNull,
              code_builder.literalMap({
                code_builder.literalSpread(): code_builder.refer('recordModel.data'),
                for (var recordFieldName in ['id', 'collectionId', 'collectionName'])
                  code_builder.refer('${className}FieldsEnum.$recordFieldName.nameInSchema'):
                      code_builder.refer('recordModel.$recordFieldName'),
                for (var field in schema)
                  if (context.generateRelationExpansions &&
                      field.type == FieldType.relation &&
                      field.collectionId != null)
                    code_builder.literalString('${field.nameInCamelCase}Expanded'): field.maxSelect == 1
                        ? code_builder
                            .refer(
                              Collection.generateClassName(
                                context.resolveCollectionName(field.collectionId!),
                              ),
                            )
                            .property('recordModelToJSONMap')
                            .call([
                            code_builder.refer('recordModel').property('get').call(
                              [
                                code_builder.literalString('expand.${field.name}'),
                                code_builder.literalNull,
                              ],
                              {},
                              [
                                code_builder.TypeReference(
                                  (b) => b
                                    ..symbol = 'RecordModel'
                                    ..url = 'package:pocketbase/pocketbase.dart'
                                    ..isNullable = true,
                                )
                              ],
                            )
                          ]).code
                        : code_builder
                            .refer('recordModel')
                            .property('get')
                            .call(
                              [
                                code_builder.literalString('expand.${field.name}'),
                                code_builder.literalNull,
                              ],
                              {},
                              [
                                code_builder.TypeReference((t) => t
                                  ..symbol = 'List'
                                  ..isNullable = true
                                  ..types.add(code_builder.TypeReference(
                                    (b) => b
                                      ..symbol = 'RecordModel'
                                      ..url = 'package:pocketbase/pocketbase.dart'
                                  ))),
                              ],
                            )
                            .nullSafeProperty('map')
                            .call([
                              code_builder.Method((m) => m
                                ..lambda = true
                                ..requiredParameters.add(
                                  code_builder.Parameter((p) => p..name = 'record'),
                                )
                                ..body = code_builder
                                    .refer(
                                      Collection.generateClassName(
                                        context.resolveCollectionName(field.collectionId!),
                                      ),
                                    )
                                    .property('recordModelToJSONMap')
                                    .call([code_builder.refer('record')]).code).closure
                            ])
                            .property('toList')
                            .call([])
              }))
          .code,
  );
}
