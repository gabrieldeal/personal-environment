# -*- mode: ruby -*-

require 'irb/ext/save-history'

IRB.conf[:SAVE_HISTORY] = 200
IRB.conf[:HISTORY_FILE] = "#{ENV['HOME']}/.irb-history"

if ENV['INSIDE_EMACS']
  puts 'Inside Emacs. Tweaking IRB.'

  IRB.conf[:USE_MULTILINE] = nil
  IRB.conf[:USE_SINGLELINE] = false
  IRB.conf[:PROMPT_MODE] = :INF_RUBY
  IRB.conf[:USE_READLINE] = false
  IRB.conf[:USE_COLORIZE] = true
end
