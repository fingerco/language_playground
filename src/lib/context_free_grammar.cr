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

  def_lex_step :translate do |match_name, translate_proc|
    Proc(Array(LexMatch), LexMatch, Array(LexMatch)).new do |matches, match|
      if match_name === match.name
        new_name = translate_proc.call(match.contents) || match.name
        matches + [LexMatch.new(new_name, match.contents, match.location)]
      else
        matches + [match]
      end
    end
  end

  def_lex_step :crunch! do |new_name, start_name, end_name|
    curr_crunched : LexMatch? = nil

    reduce_proc = Proc(Array(LexMatch), LexMatch, Array(LexMatch)).new do |matches, match|
      if !curr_crunched && start_name === match.name
        curr_crunched = LexMatch.new(new_name, match.contents, match.location)
        matches + [curr_crunched.not_nil!]

      elsif curr_crunched && end_name === match.name
        curr_crunched.not_nil!.contents += match.contents
        curr_crunched = nil
        matches

      elsif curr_crunched
        curr_crunched.not_nil!.contents += match.contents
        matches

      else
        matches + [match]
      end
    end

    end_proc = Proc(Array(LexMatch), Array(LexMatch)).new do |matches|
      if curr_crunched
        loc = "#{curr_crunched.not_nil!.location[0]}:#{curr_crunched.not_nil!.location[1]}"
        raise "No end '#{end_name}' for :crunch!(#{new_name}, #{start_name}, #{end_name}) at #{loc}"
      end

      matches
    end

    {reduce_proc, end_proc}
  end

end
