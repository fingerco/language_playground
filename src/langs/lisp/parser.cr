require "../../bases/programming_language"
require "./lexer"

class Languages::Lisp::Parser
  include ProgrammingLanguage::Parser
  alias Lexer = Languages::Lisp::Lexer
  alias Token = Lexer::Token
  alias TokenType = Lexer::TokenType

  property tokens : Array(Lexer::Token) = [] of Token

  def initialize(contents : String)
    lex = Lexer.new
    contents.each_char do |c|
      lex.parse_character(c)
    end

    lex.end_file

    @tokens = lex.tokens
  end

  def initialize(tokens : Array(Token))
    @tokens = tokens
  end

  def parse(): SyntaxTree::Node
    generator = TreeGenerator.new

    @tokens.each do |token|
      generator.parse_token(token)
    end

    generator.root
  end

  private class TreeGenerator
    property root : SyntaxTree::Node = SyntaxTree::Node.new
    def initialize
      @state = State::Neutral
    end

    def parse_token(token : Token)
      puts token
    end

    enum State
      Neutral
      ExpressionStart
      ExpressionEnd
      StringStart
      StringEnd
    end
  end

  class SyntaxTree
    class Node
    end

    class Expression < Node
    end

    class Whitespace < Node
    end

    class SymbolGeneric < Node
    end

    class SymbolNumber < Node
    end

    class DoubleString < Node
    end

    class SingleString < Node
    end
  end

  class TokenNode
    @one_of : Array(TokenNode) | Array(TokenType) | Array(SyntaxTypes) | Array(TokenType | SyntaxTypes)
    @all_of : Array(TokenNode) | Array(TokenType) | Array(SyntaxTypes) | Array(TokenType | SyntaxTypes)

    def initialize(one_of = Array(TokenType).new, all_of = Array(TokenType).new)
      @one_of = one_of
      @all_of = all_of
    end
  end

  enum SyntaxTypes
    Comment
    SymbolAny
    StringAny
    Whitespace

    FunctionContents
    FunctionContentItem
    FunctionMultipleContentItems
    Expression
    EmptyExpression
    EmptyFunctionCall
    NonEmptyFunctionCall
  end


  GRAMMAR = Grammar(SyntaxTypes, TokenNode).new

  GRAMMAR.add_node(SyntaxTypes::Expression, TokenNode.new(one_of: [
    SyntaxTypes::EmptyExpression,
    SyntaxTypes::EmptyFunctionCall,
    SyntaxTypes::NonEmptyFunctionCall,
  ]))

  GRAMMAR.add_node(SyntaxTypes::NonEmptyFunctionCall, TokenNode.new(all_of: [
    TokenType::ExpressionStart,
    SyntaxTypes::SymbolAny,
    SyntaxTypes::FunctionContents,
    TokenType::ExpressionEnd
  ]))

  GRAMMAR.add_node(SyntaxTypes::FunctionContents, TokenNode.new(one_of: [
    SyntaxTypes::FunctionMultipleContentItems,
    SyntaxTypes::FunctionContentItem,
  ]))

  GRAMMAR.add_node(SyntaxTypes::FunctionMultipleContentItems, TokenNode.new(all_of: [
    SyntaxTypes::FunctionContentItem,
    SyntaxTypes::FunctionContents
  ]))

  GRAMMAR.add_node(SyntaxTypes::FunctionContentItem, TokenNode.new(one_of: [
    TokenType::Whitespace,
    SyntaxTypes::SymbolAny,
    SyntaxTypes::StringAny,
    TokenType::Comment
  ]))

  GRAMMAR.add_node(SyntaxTypes::EmptyFunctionCall, TokenNode.new(all_of: [
    TokenType::ExpressionStart,
    SyntaxTypes::SymbolAny,
    TokenType::ExpressionEnd
  ]))

  GRAMMAR.add_node(SyntaxTypes::EmptyExpression, TokenNode.new(all_of: [
    TokenType::ExpressionStart,
    TokenType::ExpressionEnd
  ]))

  GRAMMAR.add_node(SyntaxTypes::Whitespace, TokenNode.new(one_of: [
    TokenType::Whitespace
  ]))

  GRAMMAR.add_node(SyntaxTypes::StringAny, TokenNode.new(one_of: [
    TokenType::StringDouble,
    TokenType::StringSingle
  ]))

  GRAMMAR.add_node(SyntaxTypes::SymbolAny, TokenNode.new(one_of: [
    TokenType::SymbolNumber,
    TokenType::SymbolBoolean,
    TokenType::SymbolGeneric,
  ]))

  GRAMMAR.add_node(SyntaxTypes::Comment, TokenNode.new(one_of: [
    TokenType::Comment
  ]))
end
