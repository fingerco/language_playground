require "compiler/crystal/annotatable"
require "compiler/crystal/program"
require "compiler/crystal/codegen"
require "compiler/crystal/syntax"
require "compiler/crystal/progress_tracker"
require "compiler/crystal/config"
require "compiler/crystal/crystal_path"
require "compiler/crystal/formatter"
require "compiler/crystal/macros/*"
require "compiler/crystal/macros"
require "compiler/crystal/semantic/*"
require "compiler/crystal/compiler"

DSL_FILE_PATH = ARGV[0]
ABS_DSL_LANG_PATH = "../src/langs/#{ENV["DSL_LANG"]}.cr"

# Parse the given file that uses our DSL
dsl_file_contents = File.read(DSL_FILE_PATH)
source = Crystal::Compiler::Source.new(DSL_FILE_PATH, dsl_file_contents)

# Compile the file with our DSL
compiler = Crystal::Compiler.new
compiler.prelude = ABS_DSL_LANG_PATH
compiler.compile([source], ARGV[1])
