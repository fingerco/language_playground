require "spec"
require "../../src/langs/lisp/parser"

alias Parser = Languages::Lisp::Parser

def parse(contents)
  Parser.new(contents).parse
end

describe Parser do
  describe "end-to-end" do
    it "correctly parses a basic function" do
      parse("(+ 1 2)").should eq(nil)
    end
  end
end
