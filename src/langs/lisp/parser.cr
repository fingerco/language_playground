require "../../bases/programming_language"
require "../../lib/context_free_grammar"
require "./lexer"

class Languages::Lisp::Parser < ProgrammingLanguage::Parser
  alias LexMatch = Lexer::LexMatch

  def lex
    @@lexicon.transform(@contents)
  end

  lexicon (<<-LEXICON)
    {StringDouble}  -> "
    {StringSingle}  -> '

    {Whitespace}    -> {WHITESPACE}
    {ExprStart}     -> (
    {ExprEnd}       -> )

    {SymbolGeneric} -> {ANYTHING}
    LEXICON

  add_lex_step :fold, ["Whitespace", "SymbolGeneric"]

  # lex_step :fold, ["Whitespace", "SymbolGeneric"]
  # lex_step :crunch, (<<-CRUNCH)
  #   {String} -> {StringDouble} {CONTENTS} {StringDouble}
  #   {String} -> {StringSingle} {CONTENTS} {StringSingle}
  #   CRUNCH

  grammar (<<-GRAMMAR)
    {Expr} -> {ExprStart} {SymbolAny} {ExprEnd}
    {Expr} -> {ExprStart} {SymbolAny} {ExprContents} {ExprEnd}
    {Expr} -> {ExprStart} {Whitespace} {Expr} {ExprEnd}
    {Expr} -> {ExprStart} {Whitespace} {Expr} {ExprContents} {ExprEnd}

    {ExprContents} -> {Whitespace} {ValueAny}
    {ExprContents} -> {ExprContents} {ExprContents}

    {ValueAny} -> {SymbolAny}
    {ValueAny} -> {StringAny}

    {StringAny} -> {StringDouble}
    {StringAny} -> {StringSingle}

    {SymbolAny} -> {SymbolNumber}
    {SymbolAny} -> {SymbolBoolean}
    {SymbolAny} -> {SymbolGeneric}
    GRAMMAR
end
