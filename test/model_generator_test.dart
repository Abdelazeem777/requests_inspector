import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/src/jsonToDart/model_generator.dart';

void main() {
  group('ModelGenerator Tests', () {
    const testJson = '{"name": "John", "age": 30, "email": "john@example.com"}';
    
    test('ModelGenerator should include both toJson and copyWith by default', () {
      final generator = ModelGenerator('User');
      final result = generator.generateDartClasses(testJson);
      
      expect(result.code.contains('toJson()'), isTrue);
      expect(result.code.contains('copyWith('), isTrue);
    });
    
    test('ModelGenerator.withOptions should include both toJson and copyWith when enabled', () {
      final generator = ModelGenerator.withOptions('User', false, true, true);
      final result = generator.generateDartClasses(testJson);
      
      expect(result.code.contains('toJson()'), isTrue);
      expect(result.code.contains('copyWith('), isTrue);
    });
    
    test('ModelGenerator.withOptions should exclude toJson when disabled', () {
      final generator = ModelGenerator.withOptions('User', false, false, true);
      final result = generator.generateDartClasses(testJson);
      
      expect(result.code.contains('toJson()'), isFalse);
      expect(result.code.contains('copyWith('), isTrue);
    });
    
    test('ModelGenerator.withOptions should exclude copyWith when disabled', () {
      final generator = ModelGenerator.withOptions('User', false, true, false);
      final result = generator.generateDartClasses(testJson);
      
      expect(result.code.contains('toJson()'), isTrue);
      expect(result.code.contains('copyWith('), isFalse);
    });
    
    test('ModelGenerator.withOptions should exclude both toJson and copyWith when disabled', () {
      final generator = ModelGenerator.withOptions('User', false, false, false);
      final result = generator.generateDartClasses(testJson);
      
      expect(result.code.contains('toJson()'), isFalse);
      expect(result.code.contains('copyWith('), isFalse);
    });
    
    test('Generated model should always include fromJson constructor', () {
      final generator = ModelGenerator.withOptions('User', false, false, false);
      final result = generator.generateDartClasses(testJson);
      
      // fromJson should always be included regardless of other options
      expect(result.code.contains('fromJson('), isTrue);
      expect(result.code.contains('User.fromJson'), isTrue);
    });
  });
}