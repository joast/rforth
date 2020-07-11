# frozen_string_literal: true

# forth I/O primitives.
module PrimitiveWords
  def dot(name)
    if @stack.empty?
      $stderr.print "#{name} stack underflow\n"
    else
      @s_out.print(@stack.pop)
    end
  end

  def cr(_name)
    @s_out.print "\n"
  end
end
