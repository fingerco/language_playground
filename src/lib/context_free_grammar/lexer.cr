class ContextFreeGrammar
  module Lexer
    class Lexicon
      alias LexStepProc = Proc(Array(LexMatch), Array(LexMatch))
      @matchers = {} of String => Regex | String
      property steps = [] of LexStepProc

      def self.value_for(val : String) : Regex | String
        case val
        when "{ANYTHING}" then /.+/
        when "{WHITESPACE}" then /^[\s]+$/
        else val
        end
      end

      def add_matcher(name : String, definition : String)
        @matchers[name] = Lexicon.value_for(definition)
      end

      def transform(str : String) : Array(LexMatch)
        all_matches = [] of LexMatch
        line_no : UInt32 = 1
        col_no : UInt32 = 0
        str.each_char do |c|
          col_no += 1
          match = nil
          @matchers.each do |name, val|
            if !match && val === c.to_s
              match = LexMatch.new(name, c.to_s, {line_no, col_no})
            end
          end

          unless match
            raise "Lexer - Unmatched Character: '#{c}'"
          end

          if c == '\n'
            line_no += 1
            col_no = 0
          end

          all_matches.push(match)
        end

        @steps.each do |step|
          all_matches = step.call(all_matches)
        end

        all_matches
      end
    end

    class LexMatch
      property name : String
      property contents : String
      property location : Tuple(UInt32, UInt32)

      def initialize(name, contents, location = {0_u32, 0_u32})
        @name = name
        @contents = contents
        @location = location
      end

      def combine(other : LexMatch)
        LexMatch.new(@name, @contents + other.contents, @location)
      end

      def ==(other : LexMatch)
        @name == other.name && @contents == other.contents
      end

      def to_s(io : IO)
        io.print("#{@name}('#{@contents}')")
      end

      def inspect(io : IO)
        io.print("#{@name}('#{@contents}')")
      end
    end

    class LexStepProcs
      property start_proc : Proc(Array(LexMatch), Array(LexMatch))?
      property map_proc : Proc(LexMatch, LexMatch)?
      property reduce_proc : Proc(Array(LexMatch), LexMatch, Array(LexMatch))?
      property end_proc : Proc(Array(LexMatch), Array(LexMatch))?
    end

    module Macros
      LEX_MAPPING_REGEX = /{(.+?)}[\s]+<-[\s]+(.+)/
      alias LexMatch = ContextFreeGrammar::Lexer::LexMatch
      alias Lexicon = ContextFreeGrammar::Lexer::Lexicon
      @@lexicon : Lexicon = Lexicon.new

      macro lex_grammar(lex_def)
        lines = {{lex_def}}.lines.map{|l| l.strip}.select{|l| l.size > 0}
        lines.each do |line|
          match = LEX_MAPPING_REGEX.match(line)
          unless match
            raise "Lexicon - Does not match regex: #{line}"
          end

          lex_name = match[1]
          translation = match[2]
          @@lexicon.not_nil!.add_matcher(lex_name, translation)
        end
      end

      macro def_lex_step(name, &block)
        private def self.lex_step_block_{{name.id}}({{*block.args}})
          {{block.body}}
        end

        def self.lex_step_{{name.id}}(lex, *block_args)
          procs = self.lex_step_block_{{name.id}}(*block_args)

          lex = procs.start_proc.not_nil!.call(lex) if procs.start_proc
          lex = lex.map(&procs.map_proc.not_nil!) if procs.map_proc
          lex = lex.reduce([] of LexMatch, &procs.reduce_proc.not_nil!) if procs.reduce_proc
          lex = procs.end_proc.not_nil!.call(lex) if procs.end_proc
          lex
        end
      end

      macro add_lex_step(name, *args)
        @@lexicon.steps.push (Proc(Array(LexMatch), Array(LexMatch)).new do |input|
          self.lex_step_{{name.id}}(input, {{*args}})
        end)
      end

    end
  end
end
