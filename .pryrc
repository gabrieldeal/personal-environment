# -*- mode: ruby -*-

Pry.config.pager = false
Pry.config.editor = ENV['VISUAL']

if ENV['INSIDE_EMACS']
  puts 'Inside Emacs. Tweaking Pry.'

  Pry.config.correct_indent = false
  Pry.config.pager = false
end
