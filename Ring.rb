#!/usr/bin/ruby

require './UserInterface.rb'
require './TextProcessor.rb' 
require './FileManager.rb'
require 'ostruct'

$mode = "live"

@user_interface = UserInterface.new
@text_processor = TextProcessor.new
@file_manager  = FileManager.new
    
# Eclipse Run or Run configuration must specify Ring.rb or the run will terminate
# This must be the active tab when the Run button is clicked

# Ring.rb contains the entire logic flow either in the actual instructions or associated comments.

# set up control structure for file names
$file_history = OpenStruct.new(:file01 => "", :file02 => "", :file03 => "", :file04 => "", :file05 => "", :file06 => "", :file07 => "", :file08 => "", :file09 => "")
# set up control structure for search strings
$search_history = OpenStruct.new(:search01 => "", :search02 => "", :search03 => "", :search04 => "", :search05 => "", :search06 => "", :search07 => "", :search08 => "", :search09 => "")
file_name  = @user_interface.send(:user_file_read)
text_lines = @file_manager.send(:file_directory, file_name)
             @user_interface.send(:user_pattern)                      
text_area  = @text_processor.send(:text_include, text_lines)
             @user_interface.send(:user_display, text_area) 
selection  = @user_interface.send(:user_prompt_options, text_area)
             @user_interface.send(:user_pattern) if selection == "1" || selection == "2"
text_area  = @text_processor.send(:text_include, text_lines) if selection == "1"
text_area  = @text_processor.send(:text_exclude) if selection == "2"
text_area  = @text_processor.send(:text_delete_in, text_lines) if selection == "3"
text_area  = @text_processor.send(:text_delete_ex, text_lines) if selection == "4"
text_area  = @user_interface.send(:user_prompt_ranges, text_area, text_lines) if selection == "5"
             @user_interface.send(:user_display, text_area) if ("1".."5").include?(selection) 
path      = @user_interface.send(:user_prompt_write) if selection == "6" 
            
# 
# Additional development notes:
# use assoc(line number) for line commands

