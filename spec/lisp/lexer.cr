require "spec"
require "../../src/langs/lisp/lexer"

alias Lexer = Languages::Lisp::Lexer
alias Token = Lexer::Token
alias TokenType = Lexer::TokenType
ExpressionStart = TokenType::ExpressionStart
ExpressionEnd = TokenType::ExpressionEnd
Whitespace = TokenType::Whitespace
SymbolNumber = TokenType::SymbolNumber
SymbolGeneric = TokenType::SymbolGeneric
StringDouble = TokenType::StringDouble
StringSingle = TokenType::StringSingle
Comment = TokenType::Comment

def lex_parse(contents)
  lex = Lexer.new
  contents.each_char do |c|
    lex.parse_character(c)
  end
  lex.end_file

  lex
end

describe Lexer do
  describe "end-to-end" do
    it "correctly parses a basic function" do
      content = <<-CONTENTS
      (+ 1 2)
      CONTENTS

      tokens = [
        Token.new(ExpressionStart, "("),
        Token.new(SymbolGeneric,   "+"),
        Token.new(Whitespace,      " "),
        Token.new(SymbolNumber,    "1"),
        Token.new(Whitespace,      " "),
        Token.new(SymbolNumber,    "2"),
        Token.new(ExpressionEnd,   ")"),
      ] of Lexer::Token

      lex_parse(content).tokens.should eq(tokens)
    end

    it "correctly parses a basic function" do
      content = <<-CONTENTS
      ; This is a comment
      (+ 1 2)
      CONTENTS

      tokens = [
        Token.new(Comment, "; This is a comment"),
        Token.new(Whitespace, "\n"),
        Token.new(ExpressionStart, "("),
        Token.new(SymbolGeneric,   "+"),
        Token.new(Whitespace,      " "),
        Token.new(SymbolNumber,    "1"),
        Token.new(Whitespace,      " "),
        Token.new(SymbolNumber,    "2"),
        Token.new(ExpressionEnd,   ")"),
      ] of Lexer::Token

      lex_parse(content).tokens.should eq(tokens)
    end

    it "correctly parses a basic function" do
      #https://www2.cs.sfu.ca/CourseCentral/310/pwfong/Lisp/1/tutorial1.html
      content = <<-CONTENTS
      ;;; testing.lisp
      ;;; by Philip Fong
      ;;;
      ;;; Introductory comments are preceded by ";;;"
      ;;; Function headers are preceded by ";;"
      ;;; Inline comments are introduced by ";"
      ;;;

      ;;
      ;; Triple the value of a number
      ;;

      (defun triple (X)
        "Compute three times X."  ; Inline comments can
        (* 3 X))                  ; be placed here.

      ;;
      ;; Negate the sign of a number
      ;;

      (defun negate (X)
        "Negate the value of X."  ; This is a documentation string.
        (- X))
      CONTENTS

      tokens = [
        Token.new(Comment,          ";;; testing.lisp"),
        Token.new(Whitespace,       "\n"),
        Token.new(Comment,          ";;; by Philip Fong"),
        Token.new(Whitespace,       "\n"),
        Token.new(Comment,          ";;;"),
        Token.new(Whitespace,       "\n"),
        Token.new(Comment,          ";;; Introductory comments are preceded by \";;;\""),
        Token.new(Whitespace,       "\n"),
        Token.new(Comment,          ";;; Function headers are preceded by \";;\""),
        Token.new(Whitespace,       "\n"),
        Token.new(Comment,          ";;; Inline comments are introduced by \";\""),
        Token.new(Whitespace,       "\n"),
        Token.new(Comment,          ";;;"),
        Token.new(Whitespace,       "\n\n"),
        Token.new(Comment,          ";;"),
        Token.new(Whitespace,       "\n"),
        Token.new(Comment,          ";; Triple the value of a number"),
        Token.new(Whitespace,       "\n"),
        Token.new(Comment,          ";;"),
        Token.new(Whitespace,       "\n\n"),
        Token.new(ExpressionStart,  "("),
        Token.new(SymbolGeneric,    "defun"),
        Token.new(Whitespace,       " "),
        Token.new(SymbolGeneric,    "triple"),
        Token.new(Whitespace,       " "),
        Token.new(ExpressionStart,  "("),
        Token.new(SymbolGeneric,    "X"),
        Token.new(ExpressionEnd,    ")"),
        Token.new(Whitespace,       "\n  "),
        Token.new(StringDouble,     "\"Compute three times X.\""),
        Token.new(Whitespace,       " "),
        Token.new(Comment,          "; Inline comments can"),
        Token.new(Whitespace,       "\n  "),
        Token.new(ExpressionStart,  "("),
        Token.new(SymbolGeneric,    "*"),
        Token.new(Whitespace,       " "),
        Token.new(SymbolNumber,     "3"),
        Token.new(Whitespace,       " "),
        Token.new(SymbolGeneric,    "X"),
        Token.new(ExpressionEnd,    ")"),
        Token.new(ExpressionEnd,    ")"),
        Token.new(Whitespace,       "                  "),
        Token.new(Comment,          "; be placed here."),
        Token.new(Whitespace,       "\n\n"),
        Token.new(Comment,          ";;"),
        Token.new(Whitespace,       "\n"),
        Token.new(Comment,          ";; Negate the sign of a number"),
        Token.new(Whitespace,       "\n"),
        Token.new(Comment,          ";;"),
        Token.new(Whitespace,       "\n\n"),
        Token.new(ExpressionStart,  "("),
        Token.new(SymbolGeneric,    "defun"),
        Token.new(Whitespace,       " "),
        Token.new(SymbolGeneric,    "negate"),
        Token.new(Whitespace,       " "),
        Token.new(ExpressionStart,  "("),
        Token.new(SymbolGeneric,    "X"),
        Token.new(ExpressionEnd,    ")"),
        Token.new(Whitespace,       "\n  "),
        Token.new(StringDouble,     "\"Negate the value of X.\""),
        Token.new(Whitespace,       " "),
        Token.new(Comment,          "; This is a documentation string."),
        Token.new(Whitespace,       "\n  "),
        Token.new(ExpressionStart,  "("),
        Token.new(SymbolGeneric,    "-"),
        Token.new(Whitespace,       " "),
        Token.new(SymbolGeneric,    "X"),
        Token.new(ExpressionEnd,    ")"),
        Token.new(ExpressionEnd,    ")"),
      ] of Lexer::Token

      lex_parse(content).tokens.should eq(tokens)
    end
  end

end
