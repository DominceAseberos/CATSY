import 'package:json_annotation/json_annotation.dart';

part 'category_dto.g.dart';

@JsonSerializable()
class CategoryDto {
  final String id;
  final String name;
  final String? description;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'sort_order')
  final int sortOrder;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const CategoryDto({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.sortOrder,
    required this.updatedAt,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryDtoToJson(this);
}
