library classifyDartTests;

import '../lib/src/classify_dart.dart';
import 'package:unittest/unittest.dart';

void main() {
  group('Classifies as type', () {
    validate('when core type or void', 
    	'void main(num arg1, bool arg2, int arg3, double arg4){}', 
    	'<span class="t">void</span> <span class="i">main</span>('+
    	'<span class="t">num</span> <span class="i">arg1</span>, '+
    	'<span class="t">bool</span> <span class="i">arg2</span>, '+
    	'<span class="t">int</span> <span class="i">arg3</span>, '+
    	'<span class="t">double</span> <span class="i">arg4</span>){}');
    validate('when identifier starts with uppercase', 
        'void main(MyType arg1, YourType arg2){}', 
        '<span class="t">void</span> <span class="i">main</span>('+
        '<span class="t">MyType</span> <span class="i">arg1</span>, '+
        '<span class="t">YourType</span> <span class="i">arg2</span>){}');
	});
  group('Classifies interpolated string', () {
     validate('when string contains \$identifier',
         'String str = \'this is my \$name\'',
         '<span class="t">String</span> <span class="i">str</span> = '+
         '<span class="s si">\'this is my </span><span class="s si">\$</span>'+
         '<span class="i">name</span><span class="s si">\'</span>');
  });
  group('Classifies comments', () {
    validate('when line comment',
        '// my comment',
        '<span class="c">// my comment</span>');
    validate('when block comment',
        '/*my comment\nover some\nlines*/',
        '<span class="c">/*my comment\nover some\nlines*/</span>');
  });
  group('Escapes HTML entities', () {
    validate('when present',
        '10 > 5',
        '<span class="n">10</span> &gt; <span class="n">5</span>');
  });
}

validate(String description, String input, String expected, 
         {bool verbose: false}) {
	test(description, () {
		var actual = classifyDart(input);
		var passed = (actual == expected);
		if (!passed) {
		  print('FAIL: $description');
      print('  expect: $expected');
      print('  actual: $actual');
      print('');
		}
		expect(passed, isTrue, verbose: verbose);
	});
}