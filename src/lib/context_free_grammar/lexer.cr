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
        str.each_char do |c|
          match = nil
          @matchers.each do |name, val|
            if !match && val === c.to_s
              match = LexMatch.new(name, c.to_s)
            end
          end

          unless match
            raise "Lexer - Unmatched Character: '#{c}'"
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

      def initialize(name, contents)
        @name = name
        @contents = contents
      end

      def combine(other : LexMatch)
        LexMatch.new(@name, @contents + other.contents)
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

    module Macros
      LEX_MAPPING_REGEX = /{(.+?)}[\s]+->[\s]+(.+)/
      alias LexMatch = ContextFreeGrammar::Lexer::LexMatch
      alias Lexicon = ContextFreeGrammar::Lexer::Lexicon
      @@lexicon : Lexicon = Lexicon.new

      macro lexicon(lex_def)
        lines = {{lex_def}}.lines.map{|l| l.strip}.select{|l| l.size > 0}
        lines.each do |line|
          match = LEX_MAPPING_REGEX.match(line)
          unless match
            raise "Lexicon -> Does not match regex: #{line}"
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
          reduce_proc = self.lex_step_block_{{name.id}}(*block_args)
          lex.reduce([] of LexMatch, &reduce_proc)
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
