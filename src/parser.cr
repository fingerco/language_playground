require "compiler/crystal/syntax"
require "./transformers/message_transformer"

TRANSFORMERS = [
  MessageTransformer.new
]

source = File.read("src/examples/basic_flow.cr")
parser = Crystal::Parser.new(source)
ast = parser.parse

tx = MessageTransformer.new
ast = ast.transform(tx)

# This will give you a Crystal::ASTNode
puts ast
