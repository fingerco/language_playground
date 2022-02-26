require "./context_free_grammar/lexer"

private module Macros
  extend ContextFreeGrammar::Lexer
  include ContextFreeGrammar::Lexer::Macros
  GRAMMAR_MAPPING_REGEX   = /{(.+?)}[\s]+->[\s]+(.+)/
  GRAMMAR_DEF_REGEX       = /{(.+?)}/

  macro grammar(grammar_def)
    lines = {{grammar_def}}.lines.map{|l| l.strip}.select{|l| l.size > 0}

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
  LEX_FOLD_REGEX        = /{(.+?)}[\s]+<-[\s]+(.+)/
  LEX_FOLD_DEF_REGEX    = /{(.+?)}/
  LEX_CRUNCH_REGEX      = /{(.+?)}[\s]+<-[\s]+(.+)/
  LEX_CRUNCH_DEF_REGEX  = /^{(.+?)} \_ {(.+?)}$/
  alias LexStepProcs = Lexer::LexStepProcs

  def_lex_step :fold do |grammar_def|
    lines = grammar_def.lines.map{|l| l.strip}.select{|l| l.size > 0}

    folds = lines.map do |line|
      match = LEX_FOLD_REGEX.match(line)
      unless match
        raise "Lexicon (:fold) -> Does not match regex: #{line}"
      end

      sym_name = match[1]
      from_def = match[2].scan(LEX_FOLD_DEF_REGEX).map do |m|
        m[1]
      end

      {sym_name, from_def}
    end

    step_procs = LexStepProcs.new
    step_procs.reduce_proc = Proc(Array(LexMatch), LexMatch, Array(LexMatch)).new do |matches, match|
      found_match = false
      curr_state = matches + [match]
      folds.each do |fold|
        next if found_match

        fold_name, from_def = fold
        fold_matches = curr_state.size >= from_def.size && curr_state[-from_def.size..].map{|curr| curr.name} == from_def

        if fold_matches
          found_match = true
          new_match = nil
          (curr_state[-from_def.size..]).each do |curr|
            new_match = new_match ? new_match.combine(curr) : LexMatch.new(fold_name, curr.contents, curr.location)
          end

          matches[(-from_def.size)+1..] = [new_match.not_nil!]
        end
      end

      unless found_match
        matches.push(match)
      end

      matches
    end

    step_procs
  end

  def_lex_step :translate do |match_name, translate_proc|
    step_procs = LexStepProcs.new
    step_procs.map_proc = Proc(LexMatch, LexMatch).new do |match|
      if match_name === match.name
        new_name = translate_proc.call(match.contents) || match.name
        LexMatch.new(new_name, match.contents, match.location)
      else
        match
      end
    end

    step_procs
  end

  def_lex_step :crunch! do |grammar_def|
    lines = grammar_def.lines.map{|l| l.strip}.select{|l| l.size > 0}
    crunches = lines.map do |line|
      match = LEX_CRUNCH_REGEX.match(line)
      unless match
        raise "Lexicon (:crunch) -> Does not match regex: #{line}"
      end

      sym_name = match[1]
      def_match = match[2].match(LEX_CRUNCH_DEF_REGEX)

      unless def_match
        raise "Lexicon (:crunch) -> Does not match regex ({...} _ {...}): #{match[2]}"
      end

      from_def = [def_match[1], def_match[2]]

      {sym_name, from_def}
    end

    step_procs = LexStepProcs.new
    step_procs.start_proc = Proc(Array(LexMatch), Array(LexMatch)).new do |matches|
      matches
    end

    curr_crunched : LexMatch? = nil
    curr_crunch_idx : Int32? = nil
    step_procs.reduce_proc = Proc(Array(LexMatch), LexMatch, Array(LexMatch)).new do |matches, match|
      should_append = true
      crunches.each_with_index do |crunch, i|
        next if curr_crunch_idx != nil && curr_crunch_idx != i
        new_name = crunch[0]
        start_name, end_name = crunch[1]

        if !curr_crunched && start_name === match.name
          curr_crunched = LexMatch.new(new_name, match.contents, match.location)
          curr_crunch_idx = i
          matches += [curr_crunched.not_nil!]
          should_append = false

        elsif curr_crunched && end_name === match.name
          curr_crunched.not_nil!.contents += match.contents
          curr_crunched = nil
          curr_crunch_idx = nil
          should_append = false

        elsif curr_crunched
          curr_crunched.not_nil!.contents += match.contents
          should_append = false

        end
      end

      if should_append
        matches += [match]
      end

      matches
    end

    step_procs.end_proc = Proc(Array(LexMatch), Array(LexMatch)).new do |matches|
      if curr_crunched && curr_crunch_idx
        crunch = crunches[curr_crunch_idx.not_nil!]
        new_name = crunch[0]
        start_name, end_name = crunch[1]

        loc = "#{curr_crunched.not_nil!.location[0]}:#{curr_crunched.not_nil!.location[1]}"
        raise "No end '#{end_name}' for :crunch!(#{new_name}, #{start_name}, #{end_name}) at #{loc}"
      end

      matches
    end

    step_procs
  end

end
