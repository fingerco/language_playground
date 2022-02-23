require "spec"
require "../../src/langs/lisp"

alias Lexer = Languages::Lisp::Lexer

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
      tokens = [
        Lexer::Token.new(Lexer::TokenType::ExpressionStart, "("),
        Lexer::Token.new(Lexer::TokenType::SymbolGeneric,   "+"),
        Lexer::Token.new(Lexer::TokenType::Whitespace,      " "),
        Lexer::Token.new(Lexer::TokenType::SymbolNumber,    "1"),
        Lexer::Token.new(Lexer::TokenType::Whitespace,      " "),
        Lexer::Token.new(Lexer::TokenType::SymbolNumber,    "2"),
        Lexer::Token.new(Lexer::TokenType::ExpressionEnd,   ")"),
      ] of Lexer::Token

      lex_parse("(+ 1 2)").tokens.should eq(tokens)
    end
  end

end
