module Languages::Lisp
  class Lexer
    @state : State = State::Neutral
    @memory : Array(Char) = Array(Char).new
    @curr_char : Char? = nil
    @location = {1, 0}
    property tokens : Array(Token) = Array(Token).new
    property produce_token : Proc(Token, Nil) = (->(token : Token) { })

    @token_regex = {
      symbol: /[^\s\(\)\"';]/,
      expr_start: /\(/,
      expr_end: /\)/,
      str_double: /\"/,
      str_single: /\'/,
      whitespace: /[\s]/,
      newline: /(\r|\n)/,
      comment: /;/
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
      Comment
    end

    def parse_character(c)
      @curr_char = c
      curr_state = @state

      # Fall through to Neutral if we stop seeing whitespace
      if curr_state =~ State::Whitespace && !@token_regex[:whitespace].match(c.to_s)
        shift_from!(State::Whitespace, State::Nothing)
      end

      if @state =~ State::Neutral
        case c.to_s
        when @token_regex[:symbol]
          shift_from!(State::Neutral, State::AnySymbol)
        when @token_regex[:expr_start]
          shift_from!(State::Neutral, State::ExpressionStart)
        when @token_regex[:expr_end]
          shift_from!(State::Neutral, State::ExpressionEnd)
        when @token_regex[:str_double]
          shift_from!(State::Neutral, State::DoubleStringStart)
        when @token_regex[:str_single]
          shift_from!(State::Neutral, State::SingleStringStart)
        when @token_regex[:comment]
          shift_from!(State::Neutral, State::Comment)
        when @token_regex[:whitespace]
          shift_from!(State::Neutral, State::Whitespace)
        else
          skipping_shift
        end

      elsif @state =~ State::ExpressionStart
        case c.to_s
        when @token_regex[:symbol]
          shift_from!(State::ExpressionStart, State::AnySymbol)
        when @token_regex[:str_double]
          invalid_shift!(State::DoubleStringStart)
        when @token_regex[:str_single]
          invalid_shift!(State::SingleStringStart)
        when @token_regex[:expr_end]
          shift_from!(State::ExpressionStart, State::ExpressionEnd)
        when @token_regex[:whitespace]
          shift_from!(State::ExpressionStart, State::Whitespace)
        else
          unexpected_char!(c)
        end

      elsif @state =~ State::StringStart
        case c.to_s
        when @token_regex[:str_double]
          shift_from!(State::DoubleStringStart, State::DoubleStringEnd)
        when @token_regex[:str_single]
          shift_from!(State::SingleStringStart, State::SingleStringEnd)
        else
          skipping_shift
        end

      elsif @state =~ State::AnySymbol
          case c.to_s
          when @token_regex[:whitespace]
            shift_from!(State::AnySymbol, State::Whitespace)
          when @token_regex[:expr_end]
            shift_from!(State::AnySymbol, State::ExpressionEnd)
          when @token_regex[:comment]
            shift_from!(State::AnySymbol, State::Comment)
          when @token_regex[:expr_start]
            invalid_shift!(State::ExpressionStart)
          when @token_regex[:str_double]
            invalid_shift!(State::DoubleStringStart)
          when @token_regex[:str_single]
            invalid_shift!(State::SingleStringStart)
          else
            skipping_shift
          end

        elsif @state =~ State::Comment
            case c.to_s
            when @token_regex[:newline]
              shift_from!(State::Comment, State::Whitespace)
            else
              skipping_shift
            end

        elsif @state =~ State::Whitespace
          case c.to_s
          when @token_regex[:whitespace]
            skipping_shift
          else
            invalid_shift!(State::Neutral)
          end

      else
        raise LexerUnhandledState.new("#{@state} - Memory: #{@memory} (location #{@location[0]}:#{@location[1]})")
      end

      if c == '\n'
        @location = {@location[0] + 1, 1}
      else
        @location = {@location[0], @location[1] + 1}
      end
    end

    private def skipping_shift
      @memory.push(@curr_char.not_nil!)
      false
    end

    def end_file
      set_state(State::FileEnded)
      @location = {1, 1}
    end

    private def set_state(new_state : State)
      do_next = [:reset_memory, :push_char] of Symbol
      if @state =~ State::DoubleStringEnd
        do_next = [:reset_memory]
        yield_token(Token.new(TokenType::StringDouble, @memory.join("")))

      elsif @state =~ State::SingleStringEnd
        do_next = [:reset_memory]
        yield_token(Token.new(TokenType::StringSingle, @memory.join("")))

      elsif @state =~ State::Comment
        yield_token(Token.new(TokenType::Comment, @memory.join("")))

      elsif @state =~ State::DoubleStringStart
        do_next = [:push_char]

      elsif @state =~ State::DoubleStringStart
        do_next = [:push_char]

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

      elsif @state =~ State::Nothing
        do_next = [:reset_memory, :push_char]

      elsif new_state =~ State::FileEnded
        do_next = [:reset_memory]

      elsif @memory.size > 0
        raise LexerUnhandledState.new("#{@state} - Memory: #{@memory} (location #{@location[0]}:#{@location[1]})")

      end

      @state = new_state
      if do_next.includes?(:reset_memory)
        @memory = Array(Char).new
      end

      if do_next.includes?(:push_char)
        @memory.push(@curr_char.not_nil!)
      end

      true
    end

    private def shift_from(curr_state : State, new_state : State)
      @state =~ curr_state && set_state(new_state)
    end

    private def shift_from!(curr_state : State, new_state : State)
      unless shift_from(curr_state, new_state)
        raise LexerInvalidStateChange.new("#{curr_state} to #{new_state} when actual state is #{@state} (location #{@location[0]}:#{@location[1]})")
      end
    end

    private def invalid_shift!(new_state)
      raise LexerInvalidStateChange.new("#{@state} to #{new_state} (location #{@location[0]}:#{@location[1]})")
    end

    private def unexpected_char!(c : Char | Nil)
      raise LexerUnexpectedCharacter.new("'#{c}' (location #{@location[0]}:#{@location[1]})")
    end

    private def yield_token(token : Token)
      @tokens.push(token)
      produce_token.call(token)
    end

    enum State
      Any
      Nothing
      Neutral
      SingleStringStart
      SingleStringEnd
      DoubleStringStart
      DoubleStringEnd
      StringStart
      ExpressionStart
      ExpressionEnd
      AnySymbol
      Whitespace
      Comment
      FileEnded

      def =~(other : State)
        if self === other
          true

        elsif other === State::Any
          true

        elsif other === State::Neutral
          [
            State::Nothing,
            State::DoubleStringEnd,
            State::SingleStringEnd,
            State::ExpressionEnd
          ].includes?(self)

        elsif other === State::StringStart
          [
            State::DoubleStringStart,
            State::SingleStringStart
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
