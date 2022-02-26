require "spec"
require "../../src/langs/lisp/parser"

alias Parser = Languages::Lisp::Parser
alias LexMatch = Parser::LexMatch

def lex(contents)
  Parser.new(contents).lex
end

describe Parser do
  describe "#lex" do
    it "correctly parses a basic function" do
      lex("(+ 1 2)").should eq([
        LexMatch.new("ExprStart", "("),
        LexMatch.new("SymbolGeneric", "+"),
        LexMatch.new("Whitespace", " "),
        LexMatch.new("SymbolGeneric", "1"),
        LexMatch.new("Whitespace", " "),
        LexMatch.new("SymbolGeneric", "2"),
        LexMatch.new("ExprEnd", ")")
      ])
    end
  end
end
