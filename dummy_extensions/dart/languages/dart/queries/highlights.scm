; Keywords
[
  "abstract"
  "as"
  "async"
  "await"
  "break"
  "case"
  "catch"
  "class"
  "const"
  "continue"
  "default"
  "do"
  "else"
  "enum"
  "extends"
  "external"
  "factory"
  "final"
  "finally"
  "for"
  "if"
  "implements"
  "import"
  "in"
  "interface"
  "library"
  "mixin"
  "new"
  "null"
  "operator"
  "part"
  "return"
  "static"
  "super"
  "switch"
  "this"
  "throw"
  "try"
  "typedef"
  "var"
  "void"
  "while"
  "with"
  "yield"
] @keyword

; Types
(type_identifier) @type
(class_definition name: (identifier) @type)
(enum_declaration name: (identifier) @type)
(mixin_declaration name: (identifier) @type)

; Functions
(function_signature name: (identifier) @function)
(method_signature name: (identifier) @function.method)
(constructor_signature name: (identifier) @constructor)

; Variables
(identifier) @variable

; Constants
(const_builtin) @constant.builtin
[(true) (false)] @constant.builtin.boolean
(null_literal) @constant.builtin

; Strings
(string_literal) @string
(template_substitution) @embedded

; Numbers
(decimal_integer_literal) @number
(hex_integer_literal) @number
(decimal_floating_point_literal) @number

; Comments
(comment) @comment
(documentation_comment) @comment.documentation

; Operators
[
  "="
  "+"
  "-"
  "*"
  "/"
  "%"
  "~/"
  "++"
  "--"
  "=="
  "!="
  ">"
  "<"
  ">="
  "<="
  "&&"
  "||"
  "!"
  "??"
  "??="
  "?"
  ":"
  "=>"
] @operator

; Punctuation
["(" ")" "[" "]" "{" "}"] @punctuation.bracket
["," ";" "."] @punctuation.delimiter
