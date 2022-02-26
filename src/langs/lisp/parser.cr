require "../../bases/programming_language"
require "../../lib/context_free_grammar"
require "./lexer"

class Languages::Lisp::Parser < ProgrammingLanguage::Parser
  alias LexMatch = Lexer::LexMatch

  def lex
    @@lexicon.transform(@contents)
  end

  lex_grammar (<<-LEXICON)
    {StringDouble}  <- "
    {StringSingle}  <- '

    {Whitespace}    <- {WHITESPACE}
    {ExprStart}     <- (
    {ExprEnd}       <- )

    {SymbolGeneric} <- {ANYTHING}
    LEXICON

  add_lex_step :fold, <<-FOLD
    {Whitespace}    <- {Whitespace} {Whitespace}
    {SymbolGeneric} <- {SymbolGeneric} {SymbolGeneric}
    FOLD

  add_lex_step :crunch!, <<-CRUNCH
    {String}        <- {StringDouble} _ {StringDouble}
    {String}        <- {StringSingle} _ {StringSingle}
    CRUNCH

  add_lex_step :translate, "SymbolGeneric", (Proc(String, String).new do |content|
    case content
    when /^[0-9]+$/         then "SymbolNumber"
    when /^(true|false)%/   then "SymbolBoolean"
    else "SymbolGeneric"
    end
  end)

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
