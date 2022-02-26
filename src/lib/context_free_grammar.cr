require "./context_free_grammar/lexer"

private module Macros
  extend ContextFreeGrammar::Lexer
  include ContextFreeGrammar::Lexer::Macros
  GRAMMAR_MAPPING_REGEX = /{(.+?)}[\s]+->[\s]+(.+)/
  GRAMMAR_DEF_REGEX = /{(.+?)}/

  macro grammar(grammar_def)
    lines = {{grammar_def}}.lines
      .map{|l| l.strip}
      .select{|l| l.size > 0}

    lines.each do |line|
      match = GRAMMAR_MAPPING_REGEX.match(line)
      unless match
        raise "Lexicon -> Does not match regex: #{line}"
      end

      sym_name = match[1]
      translation = match[2].scan(GRAMMAR_DEF_REGEX).map do |m|
        m[1]
      end
    end
  end
end

class ContextFreeGrammar
  include Macros

  def_lex_step :fold do |match_names|
    Proc(Array(LexMatch), LexMatch, Array(LexMatch)).new do |matches, match|
      prev_match = matches[-1]?
      matches_prev = prev_match && prev_match.name == match.name
      if matches_prev && match_names.includes?(match.name)
        matches[-1] = prev_match.not_nil!.combine(match)
      else
        matches.push(match)
      end

      matches
    end
  end
end
