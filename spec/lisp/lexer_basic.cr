require "spec"
require "../../src/langs/lisp"

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
  end

end
