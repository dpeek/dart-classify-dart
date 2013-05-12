classify_html
=============

A Dart classifier in Dart. Parses a string of Dart and wraps each token 
(keyword, identifier, string, etc) with a `span` and a defined set of CSS 
classes. Used to add syntax coloring to documentation and code examples.

Installation
------------

Add this to your `pubspec.yaml` (or create it):
```yaml
dependencies:
  classify_dart: any
```
Then run the [Pub Package Manager][pub] (comes with the Dart SDK):

    pub install

Usage
-----

```dart
import "package:classify_dart/classify_dart.dart";

main() {
  print(classifyDart("void main() { print('Hello World'); }"));
}
```

[pub]: http://www.dartlang.org/docs/pub-package-manager/
