part of '../collection.dart';

code_builder.Constructor _defaultConstructor(List<Field>? superFields, List<Field> schema, GeneratorContext context) {
  return code_builder.Constructor(
    (d) => d
      ..optionalParameters.addAll([
        if (superFields != null)
          for (var field in superFields)
            code_builder.Parameter(
              (p) => p
                ..name = field.nameInCamelCase
                ..named = true
                ..toSuper = true
                ..required = field.required == true
                ..docs.addAll([if (field.docs != null) field.docs!]),
            ),
        for (var field in schema) ...[
          code_builder.Parameter(
            (p) => p
              ..toThis = true
              ..name = field.nameInCamelCase
              ..named = true
              ..required = field.required == true
              ..docs.addAll([if (field.docs != null) field.docs!]),
          ),
          if (context.generateRelationExpansions && field.type == FieldType.relation && field.collectionId != null)
            code_builder.Parameter(
              (p) => p
                ..toThis = true
                ..name = '${field.nameInCamelCase}Expanded'
                ..named = true
                ..required = false
                ..docs.addAll([if (field.docs != null) field.docs!]),
            ),
        ]
      ]),
  );
}
