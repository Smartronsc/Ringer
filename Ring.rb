#!/usr/bin/ruby

require './UserInterface.rb'
require 'ostruct'

  # Eclipse Run or Run configuration must specify Ring.rb or the run will terminate
  # This must be the active tab when the Run button is clicked

# set up control structure for file names
$file_history = OpenStruct.new(:file01 => "", :file02 => "", :file03 => "", :file04 => "", :file05 => "", :file06 => "", :file07 => "", :file08 => "", :file09 => "")
# set up control structure for search strings
$search_history = OpenStruct.new(:search01 => "", :search02 => "", :search03 => "", :search04 => "", :search05 => "", :search06 => "", :search07 => "", :search08 => "", :search09 => "")
@user_interface = UserInterface.new
@user_interface.send(:user_file?)