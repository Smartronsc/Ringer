require 'test/unit/testcase'
require 'test/unit/autorunner'
require './UserInterface.rb'
require './TextProcessor.rb' 
require './FileManager.rb'
require 'ostruct'

class TestRing < Test::Unit::TestCase
  $mode = "test"
  
  def setup
    @user_interface = UserInterface.new
    @text_processor = TextProcessor.new
    @file_manager   = FileManager.new
    # set up control structure for file names
    $file_history   = OpenStruct.new(:file01 => "", :file02 => "", :file03 => "", :file04 => "", :file05 => "", :file06 => "", :file07 => "", :file08 => "", :file09 => "")
    # set up control structure for search strings
    $search_history = OpenStruct.new(:search01 => "", :search02 => "", :search03 => "", :search04 => "", :search05 => "", :search06 => "", :search07 => "", :search08 => "", :search09 => "")
  end
  
  def test_ring00
    puts "Processing /home/brad/runner/control00"
    ARGV.push("/home/brad/runner/control00")
    file_name  = @user_interface.send(:user_file_read)
    text_lines = @file_manager.send(:file_directory, "/home/brad/runner/testdata")
    pattern    = @user_interface.send(:user_pattern)
                 p "Test pattern is: #{pattern}"  
                 assert(pattern == "rs", ":user_pattern in test_ring got #{pattern} so something about the test commands changed")
    text_area  = @text_processor.send(:text_exclude, text_lines)
    #            text_area.each { |ta| p ta }
                 assert(text_area[14] == ["before", 4], "Failed 0010 UserInterface::text_exclude")
                 assert(text_area[15] == ["text", "15 r s t u v rstuv line1"], "Failed 00020 UserInterface::text_exclude")
    while                                                      
    text_area  = @user_interface.send(:user_display, text_area)            # Exit is contained in UserInterface::user_prompt_options  
    #           text_area.each { |ta| p ta }
    #           Test is to delete included lines from 11 to 24
                assert(text_area[10] == ["text", "10 r s t u v rstuv line0 ten"], "Failed 0030 TextProcessor::text_mixer_rdin")
                assert(text_area[24] == ["before", 13], "Failed 0040 UserInterface::text_exclude") # 13 because it deletes 2
                assert(text_area[25] == ["text", "25 r s t u v rstuv line2"], "Failed 0050 TextProcessor::text_mixer_rdin")
                end
  end

  def test_ring01
    puts "Processing /home/brad/runner/control01"
    ARGV.push("/home/brad/runner/control01")
    file_name  = @user_interface.send(:user_file_read)
    text_lines = @file_manager.send(:file_directory, "/home/brad/runner/testdata")
    pattern    = @user_interface.send(:user_pattern)
                p "Test pattern is: #{pattern}"  
                assert(pattern == "m n", ":user_pattern in test_ring got #{pattern} so something about the test commands changed")
    text_area  = @text_processor.send(:text_exclude, text_lines)
               text_area.each { |ta| p ta }
                assert(text_area[18] == ["before", 4], "Failed 0060 UserInterface::text_exclude")
                assert(text_area[19] == ["text", "19 m n o p q mnopq line1"], "Failed 00070 UserInterface::text_exclude")
                assert(text_area[40] == ["after", 1], "Failed 00080 UserInterface::text_exclude")
    while                                                        
    text_area  = @user_interface.send(:user_display, text_area)             # Exit is contained in UserInterface::user_prompt_options          
    #           text_area.each { |ta| p ta }
    #           Test is to delete excluded lines from 9 to 26
                assert(text_area[14] == ["before", 4], "Failed 0090 TextProcessor::text_mixer_rdex")
                assert(text_area[15] == ["text", "15 r s t u v rstuv line1"], "Failed 00100 TextProcessor::text_mixer_rdex")
    end
  end

end






