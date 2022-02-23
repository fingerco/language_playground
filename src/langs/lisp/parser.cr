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

  def parse()
    grammar_nodes = GRAMMAR.nodes

    curr_tokens = [] of Token
    @tokens.each do |token|
      curr_tokens.push(token)

      found_match = nil
      grammar_nodes.each do |k, v|
        next if found_match
        if v.match?(grammar_nodes, curr_tokens)
          found_match = k
          puts k, curr_tokens, v
          curr_tokens = [] of Token
        end
      end
    end
  end

  class TokenNode
    property match_type : Symbol
    property criteria : Array(TokenType) | Array(SyntaxTypes) | Array(TokenType | SyntaxTypes)

    def initialize(match_type : Symbol, criteria = Array(TokenType).new)
      @match_type = match_type
      @criteria = criteria
    end

    def match?(nodes : Hash(SyntaxTypes, TokenNode), tokens : Array(Token)): Bool
      if match_type == :one_of
        @criteria.each do |comp|
          if tokens.size == 1 && comp.is_a?(TokenType) && tokens[0].token_type == comp
            return true

          elsif comp.is_a?(SyntaxTypes)
            nested_node = nodes[comp].not_nil!
            if nested_node.match?(nodes, tokens)
              return true
            end

          end
        end

        false
      elsif match_type == :all_of
        if @criteria.size != tokens.size
          return false
        end

        @criteria.each_with_index do |comp, i|
          if comp.is_a?(TokenType) && !tokens[i].token_type == comp
            return false

          elsif comp.is_a?(SyntaxTypes)
            nested_node = nodes[comp].not_nil!
            if !nested_node.match?(nodes, tokens)
              return false
            end

          end
        end

        true
      else
        raise "Unknown grammar match criteria: #{match_type}"

      end
    end

    def to_s(io : IO)
      io.print("#{@match_type}(\"#{@criteria}\")")
    end

    def ==(other : Token)
      self.match_type == other.match_type && self.criteria == other.criteria
    end

    def inspect(io : IO)
      io.print("#{@match_type}(\"#{@criteria}\")")
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

  GRAMMAR.add_node(SyntaxTypes::Expression, TokenNode.new(:one_of, [
    SyntaxTypes::NonEmptyFunctionCall,
    SyntaxTypes::EmptyFunctionCall,
    SyntaxTypes::EmptyExpression,
  ]))

  GRAMMAR.add_node(SyntaxTypes::NonEmptyFunctionCall, TokenNode.new(:all_of, [
    TokenType::ExpressionStart,
    SyntaxTypes::SymbolAny,
    SyntaxTypes::FunctionContents,
    TokenType::ExpressionEnd
  ]))

  GRAMMAR.add_node(SyntaxTypes::FunctionContents, TokenNode.new(:one_of, [
    SyntaxTypes::FunctionMultipleContentItems,
    SyntaxTypes::FunctionContentItem,
  ]))

  GRAMMAR.add_node(SyntaxTypes::FunctionMultipleContentItems, TokenNode.new(:all_of, [
    SyntaxTypes::FunctionContents,
    SyntaxTypes::FunctionContentItem
  ]))

  GRAMMAR.add_node(SyntaxTypes::FunctionContentItem, TokenNode.new(:one_of, [
    TokenType::Whitespace,
    SyntaxTypes::SymbolAny,
    SyntaxTypes::StringAny,
    TokenType::Comment
  ]))

  GRAMMAR.add_node(SyntaxTypes::EmptyFunctionCall, TokenNode.new(:all_of, [
    TokenType::ExpressionStart,
    SyntaxTypes::SymbolAny,
    TokenType::ExpressionEnd
  ]))

  GRAMMAR.add_node(SyntaxTypes::EmptyExpression, TokenNode.new(:all_of, [
    TokenType::ExpressionStart,
    TokenType::ExpressionEnd
  ]))

  GRAMMAR.add_node(SyntaxTypes::Whitespace, TokenNode.new(:one_of, [
    TokenType::Whitespace
  ]))

  GRAMMAR.add_node(SyntaxTypes::StringAny, TokenNode.new(:one_of, [
    TokenType::StringDouble,
    TokenType::StringSingle
  ]))

  GRAMMAR.add_node(SyntaxTypes::SymbolAny, TokenNode.new(:one_of, [
    TokenType::SymbolNumber,
    TokenType::SymbolBoolean,
    TokenType::SymbolGeneric,
  ]))

  GRAMMAR.add_node(SyntaxTypes::Comment, TokenNode.new(:one_of, [
    TokenType::Comment
  ]))
end
