# frozen_string_literal: true

# forth stack manipulation primitives.
module PrimitiveWords
  def dup(name)
    if @stack.empty?
      $stderr.print "#{name} stack underflow\n"
    else
      @stack << @stack.last
    end
  end

  def q_dup(_name)
    @stack << @stack.last unless @stack.empty?
  end

  def drop(name)
    if @stack.empty?
      $stderr.print "#{name} stack underflow\n"
    else
      @stack.pop
    end
  end

  def swap(name)
    if @stack.size < 2
      $stderr.print "#{name} stack underflow: "
      dot_s
      @stack.clear
    else
      @stack += [@stack.pop, @stack.pop]
    end
  end

  def over(name)
    if @stack.size < 2
      $stderr.print "#{name} stack underflow: "
      dot_s
      @stack.clear
    else
      a = @stack.pop
      b = @stack.pop
      @stack << b << a << b
    end
  end

  def rot(name)
    if @stack.size < 3
      $stderr.print "#{name} stack underflow: "
      dot_s
      @stack.clear
    else
      a = @stack.pop
      b = @stack.pop
      c = @stack.pop
      @stack << b << a << c
    end
  end
end
