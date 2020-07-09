# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/ModuleLength

require 'pp'

# place holder
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

  def dot_s(_name = nil)
    @s_out.print("<#{@stack.size}> #{@stack}\n")
  end

  def dot_d(_name)
    pp @dictionary
  end
end

# place holder
class Dictionary
  def initialize(&block)
    @entries = {}

    # Could use "safe navigation" (&.) here, but I believe it is better to be
    # verbose in this case to make the intent very obvious.
    block.call(self) if block # rubocop:disable Style/SafeNavigation
  end

  def word(name, &block)
    @entries[name] = { name: name, block: block, immediate: false }
    self
  end

  def immediate_word(name, &block)
    @entries[name] = { name: name, block: block, immediate: true }
    self
  end

  def alias_word(name, old_name)
    entry = self[old_name]
    raise "No such word #{old_name}" unless entry

    new_entry = entry.dup
    new_entry[:name] = name
    @entries[name] = new_entry
  end

  def [](name)
    @entries[name]
  end
end

# place holder
class RForth
  include PrimitiveWords

  def initialize(s_in = $stdin, s_out = $stdout)
    @s_in = s_in
    @s_out = s_out
    @dictionary = Dictionary.new
    @stack = []
    initialize_dictionary
  end

  # Create all of the initial words.
  def initialize_dictionary
    PrimitiveWords.public_instance_methods(false).each do |m|
      method_clojure = method(m.to_sym)
      word(m.to_s, &method_clojure)
    end

    add_primitive_real_names_to_dictionary

    word(':')     { read_and_define_word }
    word('bye')   { exit }

    immediate_word('\\') { @s_in.readline }
  end

  def add_primitive_real_names_to_dictionary
    alias_word('?dup', 'q_dup')
    alias_word('+', 'plus')
    alias_word('*', 'mult')
    alias_word('-', 'subtract')
    alias_word('/', 'divide')
    alias_word('.', 'dot')
    alias_word('.S', 'dot_s')
    alias_word('.D', 'dot_d')
  end

  # Convience method that takes a word and a closure
  # and defines the word in the dictionary
  def word(name, &block)
    @dictionary.word(name, &block)
  end

  # Convience method that takes a word and a closure
  # and defines an immediate word in the dictionary
  def immediate_word(name, &block)
    @dictionary.immediate_word(name, &block)
  end

  # Convience method that takes an existing dict.
  # word and a new word and aliases the new word to
  # the old.
  def alias_word(name, old_name)
    @dictionary.alias_word(name, old_name)
  end

  # Given the name of a new words and the words
  # that make up its definition, define the
  # new word.
  def define_word(name, *words)
    @dictionary.word(name, &compile_words(*words))
  end

  # Give an array of (string) words, return
  # A block which will run all of those words.
  # Executes all immedate words, well, immediately.
  def compile_words(*words)
    blocks = []

    words.each do |word|
      entry = resolve_word(word)
      raise "no such word: #{word}" unless entry

      if entry[:immediate]
        entry[:block].call(entry[:name])
      else
        blocks << [ entry[:block], entry[:name] ] # rubocop:disable Layout/SpaceInsideArrayLiteralBrackets
      end
    end

    proc { blocks.each { |b, n| b.call(n) } }
  end

  # Read a word definition from input and
  # define the word
  # Definition looks like:
  #  new-word w1 w2 w3 ;
  def read_and_define_word
    name = read_word

    if name.nil?
      @s_out.print "\nEOF during word definition\n"
      exit 1
    end

    words = read_definition
    @dictionary.word(name, &compile_words(*words))
  end

  def read_definition
    words = []

    while (word = read_word)
      break if word == ';'

      words << word
    end

    if word.nil?
      @s_out.print "\nEOF during word definition\n"
      exit 1
    end

    words
  end

  # Given a (string) word, return the dictionary
  # entry for that word or nil.
  def resolve_word(word)
    return @dictionary[word] if @dictionary[word]

    x = to_number(word)

    if x
      block = proc { @stack << x }
      return { name: word, block: block, immediate: false }
    end

    nil
  end

  # Evaluate the given word.
  def forth_eval(word)
    entry = resolve_word(word)

    if entry
      entry[:block].call(entry[:name])
    else
      @s_out.puts "#{word} ??"
    end
  end

  # Try to turn the word into a number, return nil if
  # conversion fails
  def to_number(word)
    begin
      return Integer(word)
    rescue ArgumentError, FloatDomainError, Math::DomainError
      # keep rubocop from complaining about suppressed exceptions
    end

    begin
      return Float(word)
    rescue ArgumentError, FloatDomainError, Math::DomainError
      # keep rubocop from complaining about suppressed exceptions
    end

    nil
  end

  def read_word
    result = String.new

    loop do
      begin
        ch = @s_in.readchar
      rescue EOFError
        break
      end

      if /\s/ =~ ch.chr
        break unless result.empty?
      else
        result << ch
      end
    end

    result.empty? ? nil : result
  end

  def run
    loop do
      @s_out.flush
      word = read_word
      break if word.nil?

      forth_eval(word)
    end
  end
end

# rubocop:enable Metrics/ClassLength
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/ModuleLength

RForth.new.run
