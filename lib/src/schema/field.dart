import 'package:json_annotation/json_annotation.dart';
import 'package:code_builder/code_builder.dart' as code_builder;
import 'package:pocketbase_utils/src/generator/generator_context.dart';
import 'package:pocketbase_utils/src/schema/collection/collection.dart';
import 'package:pocketbase_utils/src/templates/date_time_json_methods.dart';
import 'package:pocketbase_utils/src/utils/string_utils.dart';
import 'package:pocketbase_utils/src/utils/utils.dart';
import 'package:recase/recase.dart';

part 'field.g.dart';

enum FieldType {
  text,
  editor,
  number,
  bool,
  email,
  url,
  date,
  autodate,
  select,
  relation,
  file,
  json,
  password,
  geoPoint,
}

@JsonSerializable()
final class Field {
  const Field({
    required this.name,
    required this.type,
    this.maxSelect,
    this.min,
    this.max,
    this.onlyInt,
    this.required,
    this.collectionId,
    this.id,
    this.values,
    this.hidden = false,
    this.system = false,
    this.docs,
  });

  final String? id;
  final String name;
  final String? collectionId;
  final FieldType type;
  final bool? required;
  final int? maxSelect;
  @JsonKey(fromJson: jsonValueParseToInt)
  final int? min;
  @JsonKey(fromJson: jsonValueParseToInt)
  final int? max;
  final bool? onlyInt;
  final List<String>? values;
  final bool hidden;
  final bool system;
  final String? docs;

  String get nameInCamelCase => ReCase(name).camelCase;

  factory Field.fromJson(Map<String, dynamic> json) => _$FieldFromJson(json);

  Map<String, dynamic> toJson() => _$FieldToJson(this);

  bool get hiddenOrSystem => hidden || system;

  String enumTypeName(String className) => '$className${name.capFirstChar()}Enum';

  code_builder.Reference fieldTypeRef(String className, {forceNullable = false}) {
    var fieldTypeRef = switch (type) {
      FieldType.text || FieldType.editor || FieldType.email || FieldType.url || FieldType.password => 'String',
      FieldType.number => onlyInt == true ? 'int' : 'double',
      FieldType.bool => 'bool',
      FieldType.date => 'DateTime',
      FieldType.autodate => 'DateTime',
      FieldType.select => maxSelect == 1 ? enumTypeName(className) : 'List<${enumTypeName(className)}>',
      FieldType.relation => maxSelect == 1 ? 'String' : 'List<String>',
      FieldType.file => maxSelect == 1 ? 'String' : 'List<String>',
      FieldType.json => 'dynamic',
      FieldType.geoPoint => 'GeoPoint',
    };

    if ((required != true || forceNullable) && fieldTypeRef != 'dynamic') {
      fieldTypeRef += '?';
    }

    return code_builder.refer(fieldTypeRef);
  }

  code_builder.Expression? fieldAnnotation(String className) {
    code_builder.Expression? result;

    final jsonKeyNamedArguments = <String, code_builder.Expression>{
      if (type == FieldType.date) ...{
        'toJson': required == true
            ? code_builder.refer(pocketBaseDateTimeToJsonMethodName)
            : code_builder.refer(pocketBaseNullableDateTimeToJsonMethodName),
        'fromJson': required == true
            ? code_builder.refer(pocketBaseDateTimeFromJsonMethodName)
            : code_builder.refer(pocketBaseNullableDateTimeFromJsonMethodName),
      },
      if (name != nameInCamelCase) 'name': code_builder.literal(name),
    };

    if (jsonKeyNamedArguments.isNotEmpty) {
      result = code_builder.refer('JsonKey', 'package:json_annotation/json_annotation.dart').newInstance(
        [],
        jsonKeyNamedArguments,
      );
    }

    return result;
  }

  code_builder.Field toCodeBuilder(String className) {
    return code_builder.Field((f) {
      final annotation = fieldAnnotation(className);

      f
        ..name = nameInCamelCase
        ..modifier = code_builder.FieldModifier.final$
        ..type = fieldTypeRef(className)
        ..annotations.addAll([
          if (annotation != null) annotation,
        ]);
    });
  }

  List<code_builder.Directive> toImportDirective(GeneratorContext context) {
    // If field is a relation, add import for the collection class
    if (context.generateRelationExpansions && type == FieldType.relation && collectionId != null) {
      return [
        code_builder.Directive.import(
          '${Collection.generateFileName(context.resolveCollectionName(collectionId!))}.dart',
        ),
      ];
    }
    return [];
  }

  List<code_builder.Field> additionalFieldOptionsAsFields(GeneratorContext context) {
    // Locate all files that will need to be imported for relation fields
    if (type == FieldType.relation && collectionId != null) {}

    return [
      if (min != null)
        code_builder.Field((f) => f
          ..static = true
          ..modifier = code_builder.FieldModifier.constant
          ..name = '${name}MinValue'
          ..assignment = code_builder.Code(min.toString())),
      if (max != null)
        code_builder.Field((f) => f
          ..static = true
          ..modifier = code_builder.FieldModifier.constant
          ..name = '${name}MaxValue'
          ..assignment = code_builder.Code(max.toString())),
      // If field is a relation, add a expanded field for the expanded variant
      if (context.generateRelationExpansions && type == FieldType.relation && collectionId != null) ...[
        code_builder.Field((f) => f
          ..name = '${nameInCamelCase}Expanded'
            ..modifier = code_builder.FieldModifier.final$
            ..type = maxSelect == 1
              ? code_builder.TypeReference((t) => t
                ..symbol = Collection.generateClassName(context.resolveCollectionName(collectionId!))
                ..isNullable = true)
              : code_builder.TypeReference((t) => t
              ..symbol = 'List'
              ..isNullable = true
              ..types.add(
                code_builder.refer(Collection.generateClassName(context.resolveCollectionName(collectionId!)), null)))),
      ]
    ];
  }
}

const baseFields = [
  Field(
    name: 'id',
    type: FieldType.text,
    required: true,
    system: true,
  ),
  Field(
    name: 'collectionId',
    type: FieldType.text,
    required: true,
    system: true,
  ),
  Field(
    name: 'collectionName',
    type: FieldType.text,
    required: true,
    system: true,
  ),
];

const authFields = [
  ...baseFields,
  Field(
    name: 'username',
    type: FieldType.text,
    required: true,
  ),
  Field(
    name: 'email',
    type: FieldType.email,
    required: true,
  ),
  Field(
    name: 'emailVisibility',
    type: FieldType.bool,
    required: true,
  ),
  Field(
    name: 'verified',
    type: FieldType.bool,
    required: true,
  ),
  Field(
    name: 'passwordConfirm',
    type: FieldType.text,
    hidden: true,
    required: false,
  )
];
