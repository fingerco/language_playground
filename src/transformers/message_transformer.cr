require "compiler/crystal/syntax"

class MessageTransformer < Crystal::Transformer
  def transform(node : Crystal::Call) : Crystal::ASTNode
    puts "Call definition for #{node.name} at #{node.location}"
    super(node)
  end
end
