// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library classify_dart;

import 'package:analyzer_experimental/src/generated/java_core.dart';
import 'package:analyzer_experimental/src/generated/scanner.dart';

String classifyDart(String src) {
  var buf = new StringBuffer();
  var pos = 0;
  
  var token = new StringScanner(null, src, null).tokenize();
  while (token.type != TokenType.EOF) {
    // If not a token and not whitespace assume comment. 
    var comment = src.substring(pos, token.offset);
    if (comment.trim().length > 0) {
      _addSpan(buf, Classification.COMMENT, comment);
    }
    else buf.write(comment);
    pos = token.end;
    
    // Check if string interpolation expression.
    var isString = (token.type == TokenType.STRING 
        || token.type == TokenType.STRING_INTERPOLATION_EXPRESSION 
        || token.type == TokenType.STRING_INTERPOLATION_IDENTIFIER);
    var stringClass = isString ? ' ${Classification.STRING_INTERPOLATION}' : '';
    
    var cls = _classify(token);
    if (cls == '' && stringClass == '') buf.write(_escapeHtml(token.lexeme));
    else _addSpan(buf, '$cls$stringClass', token.lexeme);
    token = token.next;
  }
  
  var remain = src.substring(pos, token.offset);
  if (remain.trim().length > 0) {
    // Add remaining as comment.
    _addSpan(buf, Classification.COMMENT, remain);
  } else {
    // Add remaining whitespace.
    buf.write(remain);
  }
  
  return buf.toString();
}

Map _createTokenMap() {
  var map = new Map();
  [ TokenType.OPEN_PAREN,
    TokenType.CLOSE_PAREN,
    TokenType.OPEN_CURLY_BRACKET,
    TokenType.CLOSE_CURLY_BRACKET,
    TokenType.OPEN_SQUARE_BRACKET,
    TokenType.OPEN_SQUARE_BRACKET,
    TokenType.COLON,
    TokenType.SEMICOLON,
    TokenType.COMMA,
    TokenType.PERIOD,
    TokenType.PERIOD_PERIOD
  ].forEach((t) => map[t] = Classification.NONE);
  
  [ TokenType.INT,
    TokenType.HEXADECIMAL,
    TokenType.DOUBLE
  ].forEach((t) => map[t] = Classification.NUMBER);
  
  [ TokenType.STRING,
    TokenType.STRING_INTERPOLATION_IDENTIFIER,
    TokenType.STRING_INTERPOLATION_EXPRESSION,
    TokenType.DOUBLE
  ].forEach((t) => map[t] = Classification.STRING);
  
  [ TokenType.PLUS_PLUS,
    TokenType.MINUS_MINUS,
    TokenType.TILDE,
    TokenType.BANG,
    TokenType.EQ,
    TokenType.BAR_EQ,
    TokenType.CARET_EQ,
    TokenType.AMPERSAND_EQ,
    TokenType.LT_LT_EQ,
    TokenType.GT_GT_EQ,
    TokenType.PLUS_EQ,
    TokenType.MINUS_EQ,
    TokenType.STAR_EQ,
    TokenType.SLASH_EQ,
    TokenType.TILDE_SLASH_EQ,
    TokenType.PERCENT_EQ,
    TokenType.QUESTION,
    TokenType.BAR_BAR,
    TokenType.AMPERSAND_AMPERSAND,
    TokenType.BAR,
    TokenType.CARET,
    TokenType.AMPERSAND,
    TokenType.LT_LT,
    TokenType.GT_GT,
    TokenType.PLUS,
    TokenType.MINUS,
    TokenType.STAR,
    TokenType.SLASH,
    TokenType.TILDE_SLASH,
    TokenType.PERCENT,
    TokenType.EQ_EQ,
    TokenType.BANG_EQ,
    TokenType.LT,
    TokenType.GT,
    TokenType.LT_EQ,
    TokenType.GT_EQ,
    TokenType.INDEX,
    TokenType.INDEX_EQ,
  ].forEach((t) => map[t] = Classification.NONE);
  
  // => is so awesome it is in a class of its own.
  map[TokenType.FUNCTION] = Classification.NONE;
  
  map[TokenType.IDENTIFIER] = Classification.IDENTIFIER;
  map[TokenType.KEYWORD] = Classification.KEYWORD;
  map[TokenType.HASH] = Classification.KEYWORD;
  
  return map;
}

var _tokenMap = _createTokenMap();

String _classify(Token token) {
  if (!_tokenMap.containsKey(token.type)) {
    return Classification.NONE;
  }
  var classification = _tokenMap[token.type];
  
  // Special case for names that look like types.
  if (classification == Classification.IDENTIFIER) {
    final text = token.lexeme;
    if (_looksLikeType(text)
        || text == 'num'
        || text == 'bool'
        || text == 'int'
        || text == 'double') {
      return Classification.TYPE_IDENTIFIER;
    }
  }
  
  // Color keyword token. Most are colored as keywords.
  if (classification == Classification.KEYWORD) {
    if (token.lexeme == 'void') {
      // Color "void" as a type.
      return Classification.TYPE_IDENTIFIER;
    }
    if (token.lexeme == 'this' || token.lexeme == 'super') {
      // Color "this" and "super" as identifiers.
      return Classification.SPECIAL_IDENTIFIER;
    }
  }
  
  return classification;
}

bool _looksLikeType(String name) {
  // If the name looks like an UppercaseName, assume it's a type.
  return _looksLikePublicType(name) || _looksLikePrivateType(name);
}

bool _looksLikePublicType(String name) {
  // If the name looks like an UppercaseName, assume it's a type.
  return name.length >= 2 && _isUpper(name[0]) && _isLower(name[1]);
}

bool _looksLikePrivateType(String name) {
  // If the name looks like an _UppercaseName, assume it's a type.
  return (name.length >= 3 && name[0] == '_' && _isUpper(name[1])
    && _isLower(name[2]));
}

// These ensure that they don't return "true" if the string only has symbols.
bool _isUpper(String s) => s.toLowerCase() != s;
bool _isLower(String s) => s.toUpperCase() != s;

class Classification {
  static const NONE = "";
  static const ERROR = "e";
  static const COMMENT = "c";
  static const IDENTIFIER = "i";
  static const KEYWORD = "k";
  static const OPERATOR = "o";
  static const STRING = "s";
  static const NUMBER = "n";
  static const PUNCTUATION = "p";
  static const TYPE_IDENTIFIER = "t";
  static const SPECIAL_IDENTIFIER = "r";
  static const ARROW_OPERATOR = "a";
  static const STRING_INTERPOLATION = 'si';
}

String _addSpan(StringBuffer buffer, String cls, String text) {
  buffer.write('<span class="$cls">${_escapeHtml(text)}</span>');
}

/// Replaces `<`, `&`, and `>`, with their HTML entity equivalents.
String _escapeHtml(String html) {
  return html.replaceAll('&', '&amp;')
             .replaceAll('<', '&lt;')
             .replaceAll('>', '&gt;');
}
