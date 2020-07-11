# frozen_string_literal: true

# forth math primitives.
module PrimitiveWords
  def plus(name)
    if @stack.size < 2
      $stderr.print "#{name} stack underflow: "
      dot_s
      @stack.clear
    else
      @stack << (@stack.pop + @stack.pop)
    end
  end

  def mult(name)
    if @stack.size < 2
      $stderr.print "#{name} stack underflow: "
      dot_s
      @stack.clear
    else
      @stack << (@stack.pop * @stack.pop)
    end
  end

  def subtract(name)
    if @stack.size < 2
      $stderr.print "#{name} stack underflow: "
      dot_s
      @stack.clear
    else
      a = @stack.pop
      b = @stack.pop
      @stack << b - a
    end
  end

  def divide(name)
    if @stack.size < 2
      $stderr.print "#{name} stack underflow: "
      dot_s
      @stack.clear
    else
      a = @stack.pop
      b = @stack.pop
      @stack << b / a
    end
  end
end
