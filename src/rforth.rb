# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength

require_relative 'dictionary'
require_relative 'prim_math'
require_relative 'prim_io'
require_relative 'prim_stack'
require_relative 'prim_misc'

# The forth controller. Handles input, parsing, running, etc.
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

RForth.new.run
