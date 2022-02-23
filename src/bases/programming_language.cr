module ProgrammingLanguage
  macro based_off_of(other_language)
    include {{other_language}}
  end

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
