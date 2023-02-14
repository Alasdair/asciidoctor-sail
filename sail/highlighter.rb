# frozen_string_literal: true

require 'rouge'

class SailLexer < Rouge::RegexLexer
  title 'Sail'
  desc 'Sail ISA Description Language (https://github.com/rems-project/sail)'
  tag 'sail'
  filenames '*.sail'

  id = /[a-zA-Z_?][a-zA-Z0-9_?#]*/

  tyvar = /'[a-zA-Z_?][a-zA-Z0-9_?#]*/

  # We are careful with the definition of operators for comment
  # openers like // and /* cannot prefix valid operators
  op_char = '[!%&*+-./:<=>@^|]'
  op_char_no_slash = '[!%&*+-.:<=>@^|]'
  op_char_no_slash_star = '[!%&+-.:<=>@^|]'
  op_suffix = "#{op_char}*(_#{id.source})"

  operator1 = Regexp.new(op_char)
  operator2 = Regexp.new("(#{op_char}#{op_char_no_slash_star})|(#{op_char_no_slash}#{op_char})")
  operatorn = Regexp.new("(#{op_char}#{op_char_no_slash_star}#{op_suffix})|(#{op_char_no_slash}#{op_char}#{op_suffix})")

  def self.keywords
    @keywords ||= Set.new %w[
      and as by match clause default operator function val let var forall mapping return throw catch if then else register ref pure monadic union foreach do while until repeat
    ]
  end

  # Keywords that appear in types, and builtin special types
  def self.keywords_type
    @keywords_type ||= Set.new %w[
      Int Order Bool bitvector bits inc dec unit
    ]
  end

  # These keywords appear like special functions rather than regular
  # keywords, i.e. `assert(cond, "message")`
  def self.builtins
    @builtins ||= Set.new %w[
      assert exit sizeof true false bitone bitzero undefined constraint mutual
    ]
  end

  # Reserved and internal keywords, as well as deprecated keywords
  def self.reserved
    @reserved ||= Set.new %w[
      import module internal_plet internal_return cast effect
    ]
  end

  state :whitespace do
    rule(/\s+/, Text::Whitespace)
  end

  state :root do
    mixin :whitespace

    rule(/0x[0-9A-Fa-f]+/, Num::Hex)
    rule(/0b[0-1]+/, Num::Bin)
    rule(/[0-9]+\.[0-9]+/, Num::Float)
    rule(/[0-9]+/, Num::Integer)

    rule(/"/, Str, :string)

    rule tyvar, Name::Variable

    rule(/(val\b)(\s+)(#{id})/) do
      groups Keyword, Text::Whitespace, Name::Function
    end

    rule(/(function\b)(\s+)(#{id})/) do
      groups Keyword, Text::Whitespace, Name::Function
    end

    rule %r{//}, Comment, :line_comment
    rule %r{/\*}, Comment, :comment
    rule(/\$#{id}/, Comment::Preproc, :pragma)

    # Function arrows
    rule(/->/, Punctuation)

    # Two character brackets
    rule(/\[\|/, Punctuation)
    rule(/\|\]/, Punctuation)
    rule(/{\|/, Punctuation)
    rule(/\|}/, Punctuation)

    rule(/[,@=(){}\[\];:]/, Punctuation)
    rule operatorn, Operator
    rule operator2, Operator
    rule operator1, Operator

    rule id do |m|
      name = m[0]

      if self.class.keywords.include? name
        token Keyword
      elsif self.class.keywords_type.include? name
        token Keyword::Type
      elsif self.class.builtins.include? name
        token Name::Builtin
      elsif self.class.reserved.include? name
        token Keyword::Reserved
      else
        token Name
      end
    end
  end

  state :string do
    rule(/"/, Str, :pop!)
    # Sail escape sequences are a subset of OCaml's https://v2.ocaml.org/manual/lex.html#escape-sequence
    rule(/\\([\\ntbr"']|x[a-fA-F0-9]{2}|[0-7]{3})/, Str::Escape)
    rule(/[^\\"\n]+/, Str)
  end

  state :pragma do
    rule(/\n/, Text::Whitespace, :pop!)
    rule(/[^\n]+/, Comment::Preproc)
  end

  state :line_comment do
    rule(/\n/, Text::Whitespace, :pop!)
    rule(/[^\n]+/, Comment)
  end

  state :comment do
    rule %r{/\*}, Comment, :comment
    rule %r{\*/}, Comment, :pop!
    rule(/\n/, Text::Whitespace)
    rule(/./, Comment)
  end
end
