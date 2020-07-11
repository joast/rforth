# frozen_string_literal: true

# The forth dictionnary.
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
