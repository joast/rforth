# frozen_string_literal: true

require 'pp'

# miscellaneous forth primitives.
module PrimitiveWords
  # dump the stack
  def dot_s(_name = nil)
    @s_out.print("<#{@stack.size}> #{@stack}\n")
  end

  # dump the dictionary
  def dot_d(_name)
    pp @dictionary
  end
end
