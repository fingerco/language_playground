require "../lib/context_free_grammar"
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

  abstract class Parser < ContextFreeGrammar
    @contents : String = ""

    def initialize(contents : String) : Parser
      @contents = contents
      self
    end

    abstract def lex
  end
end
