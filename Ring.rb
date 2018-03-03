#!/usr/bin/ruby

require './UserInterface.rb'
require './TextProcessor.rb' 
require './FileManager.rb'
require 'ostruct'

@user_interface = UserInterface.new
@text_processor = TextProcessor.new
@file_manager  = FileManager.new
    
# Eclipse Run or Run configuration must specify Ring.rb or the run will terminate
# This must be the active tab when the Run button is clicked

# set up control structure for file names
$file_history = OpenStruct.new(:file01 => "", :file02 => "", :file03 => "", :file04 => "", :file05 => "", :file06 => "", :file07 => "", :file08 => "", :file09 => "")
# set up control structure for search strings
$search_history = OpenStruct.new(:search01 => "", :search02 => "", :search03 => "", :search04 => "", :search05 => "", :search06 => "", :search07 => "", :search08 => "", :search09 => "")
#            Enter file name or "enter" for directory
file_name  = @user_interface.send(:user_file_read)
#            @file_name = user_selection(file_information)
text_lines = @file_manager.send(:file_directory, file_name)
p text_lines
#            @file_information = file_get_more_information(selection)     while a directory
#            file_history_push(@file)                                     record history on we have file to use 
#            text_lines = file_open(@file, "r")                           open the file to get started 
pattern    = @user_interface.send(:user_pattern)
#            $search_history["#{index}"] = "#{@pattern}"                  store it for TextProcessor class    
text_area  = @text_processor.send(:text_exclude, text_lines)
selection  = @user_interface.send(:user_display, text_area)
#            user_options() after original exclude display is presented
