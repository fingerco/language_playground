module ProgrammingLanguage

  module Language
    macro based_off_of(other_language)
      include {{other_language}}
    end
  end

  module Lexer
    class LexerInvalidStateChange < Exception
      def message
        "Lexer - Invalid State Change: #{@message}"
      end
    end

    class LexerUnhandledState < Exception
      def message
        "Lexer - Unhandled state: #{@message}"
      end
    end

    class LexerUnexpectedCharacter < Exception
      def message
        "Lexer - Unexpected Character: #{@message}"
      end
    end
  end

  module Parser
    class Grammar(ST, N)
      @nodes = Hash(ST, N).new

      def add_node(name : ST, node : N)
        @nodes[name] = node
      end

    end
  end
end
