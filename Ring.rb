#!/usr/bin/ruby

require './UserInterface.rb'

  # Eclipse Run or Run configuration must specify Ring.rb or the run will terminate
  # This must be the active tab when the Run button is clicked

DisplayMap = Struct.new(:file_name, :excluded_values)
@user_processor = UserInterface.new
@user_processor.send(:user_file?)
