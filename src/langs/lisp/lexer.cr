module Languages::Lisp
  class Lexer
    @state : State = State::Neutral
    @memory : Array(Char) = Array(Char).new
    @curr_char : Char? = nil
    property tokens : Array(Token) = Array(Token).new
    property produce_token : Proc(Token, Nil) = (->(token : Token) { })

    @token_regex = {
      symbol: /[^\s\(\)\"']/,
      expr_start: /\(/,
      expr_end: /\)/,
      str_double: /\"/,
      str_single: /\'/,
      whitespace: /[\s]/
    }

    enum TokenType
      Whitespace
      StringDouble
      StringSingle
      ExpressionStart
      ExpressionEnd
      SymbolNumber
      SymbolBoolean
      SymbolGeneric
    end

    def parse_character(c)
      @curr_char = c

      did_shift = if @state =~ State::Neutral
        case c.to_s
        when @token_regex[:symbol]
          shift_from!(State::Neutral, State::AnySymbol)
        when @token_regex[:expr_start]
          shift_from!(State::Neutral, State::ExpressionStart)
        when @token_regex[:str_double]
          shift_from!(State::Neutral, State::DoubleStringStart)
        when @token_regex[:str_single]
          shift_from!(State::Neutral, State::SingleStringStart)
        else
          false
        end

      elsif @state =~ State::ExpressionBrace
        case c.to_s
        when @token_regex[:symbol]
          shift_from!(State::ExpressionStart, State::AnySymbol)
        when @token_regex[:str_double]
          invalid_shift!(State::DoubleStringStart)
        when @token_regex[:str_single]
          invalid_shift!(State::SingleStringStart)
        when @token_regex[:expr_end]
          shift_from(State::ExpressionStart, State::ExpressionEnd) ||
          invalid_shift!(State::ExpressionEnd)
        else
          false
        end

      elsif @state =~ State::AnyString
        case c.to_s
        when @token_regex[:str_double]
          shift_from(State::DoubleStringStart, State::DoubleStringEnd)
        when @token_regex[:str_single]
          shift_from(State::SingleStringStart, State::SingleStringEnd)
        else
          false
        end

      elsif @state =~ State::AnySymbol
          case c.to_s
          when @token_regex[:whitespace]
            shift_from!(State::AnySymbol, State::Whitespace)
          when @token_regex[:expr_end]
            shift_from!(State::AnySymbol, State::ExpressionEnd)
          when @token_regex[:expr_start]
            invalid_shift!(State::ExpressionStart)
          when @token_regex[:str_double]
            invalid_shift!(State::DoubleStringStart)
          when @token_regex[:str_single]
            invalid_shift!(State::SingleStringStart)
          else
            false
          end

      else
        raise LexerUnhandledState.new("State: #{@state} - Memory: #{@memory}")
      end

      if !did_shift
        @memory.push(@curr_char.not_nil!)
      end
    end

    def end_file
      set_state(State::FileEnded)
    end

    private def set_state(new_state : State)
      cause_char = @curr_char.not_nil!

      should_reset_memory = true
      if @state =~ State::DoubleStringEnd
        @memory.push(cause_char)
        should_reset_memory = true
        yield_token(Token.new(TokenType::StringDouble, @memory.join("")))

      elsif @state =~ State::SingleStringEnd
        @memory.push(cause_char)
        should_reset_memory = true
        yield_token(Token.new(TokenType::StringSingle, @memory.join("")))

      elsif @state =~ State::DoubleStringStart
        # Do nothing

      elsif @state =~ State::DoubleStringStart
        # Do nothing

      elsif @state =~ State::ExpressionStart
        yield_token(Token.new(TokenType::ExpressionStart, @memory.join("")))

      elsif @state =~ State::ExpressionEnd
        yield_token(Token.new(TokenType::ExpressionEnd, @memory.join("")))

      elsif @state =~ State::Whitespace
        yield_token(Token.new(TokenType::Whitespace, @memory.join("")))

      elsif @state =~ State::AnySymbol
        symbol_val = @memory.join("")
        symbol_type = case symbol_val
        when /[0-9\.\_]+/
          TokenType::SymbolNumber
        when /(true|false)/
          TokenType::SymbolBoolean
        else
          TokenType::SymbolGeneric
        end

        yield_token(Token.new(symbol_type, symbol_val))
      elsif new_state =~ State::FileEnded

      elsif @memory.size > 0
        raise LexerUnhandledState.new("State: #{@state} - Memory: #{@memory}")

      end

      @state = new_state
      if should_reset_memory
        @memory = Array(Char).new
      else
        @memory.push(cause_char)
      end

      true
    end

    private def shift_from(curr_state : State, new_state : State)
      @state =~ curr_state && set_state(new_state)
    end

    private def shift_from!(curr_state : State, new_state : State)
      unless shift_from(curr_state, new_state)
        raise LexerInvalidStateChange.new("#{curr_state} to #{new_state} when actual state is #{@state}")
      end
    end

    private def invalid_shift!(new_state)
      raise LexerInvalidStateChange.new("#{@state} to #{new_state}")
    end

    private def yield_token(token : Token)
      @tokens.push(token)
      produce_token.call(token)
    end

    enum State
      Any
      Neutral
      SingleStringStart
      SingleStringEnd
      DoubleStringStart
      DoubleStringEnd
      AnyString
      ExpressionBrace
      ExpressionStart
      ExpressionEnd
      AnySymbol
      Whitespace
      FileEnded

      def =~(other : State)
        if self === other
          true

        elsif other === State::Any
          true

        elsif other === State::ExpressionBrace
          [State::ExpressionStart, State::ExpressionEnd].includes?(self)

        elsif other === State::Neutral
          [State::Whitespace].includes?(self)

        elsif other === State::AnyString
          [
            State::DoubleStringStart,
            State::SingleStringStart,
            State::DoubleStringEnd,
            State::SingleStringEnd
          ].includes?(self)

        else
          false

        end
      end
    end

    class Token
      getter token_type : TokenType
      getter val        : String = ""

      def initialize(token_type, val)
        @token_type = token_type
        @val = val
      end

      def to_s(io : IO)
        io.print("#{@token_type}(\"#{@val}\")")
      end

      def ==(other : Token)
        self.token_type == other.token_type && self.val == other.val
      end

      def inspect(io : IO)
        io.print("#{@token_type}(\"#{@val}\")")
      end
    end
  end
end
