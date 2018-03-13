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
    @file_manager  = FileManager.new
    # set up control structure for file names
    $file_history  = OpenStruct.new(:file01 => "", :file02 => "", :file03 => "", :file04 => "", :file05 => "", :file06 => "", :file07 => "", :file08 => "", :file09 => "")
    # set up control structure for search strings
    $search_history = OpenStruct.new(:search01 => "", :search02 => "", :search03 => "", :search04 => "", :search05 => "", :search06 => "", :search07 => "", :search08 => "", :search09 => "")
  end  
   
  def test_ring0100
    puts "Processing /home/brad/runner/control0100 for test of 1. Additional include pattern in TextProcessor::text_mixer_include"
    ARGV.push("/home/brad/runner/control0100")
    file_name  = @user_interface.send(:user_file_read)
    text_lines = @file_manager.send(:file_directory, "/home/brad/runner/testdata")
    pattern    = @user_interface.send(:user_pattern)
                 p "Test pattern is: #{pattern}"  
                 assert(pattern == "4", ":user_pattern in test_ring got #{pattern} so something about control0100")
    text_area  = @text_processor.send(:text_include, text_lines)
    #            text_area.each { |ta| p ta }
                 assert(text_area[3] == ["before", 3], "Failed 0100 UserInterface::text_include")
                 assert(text_area[4] == ["text", " 4 m n o p q mnopq line0"], "Failed 00110 UserInterface::text_include")
                 assert(text_area[5] == ["fill", ""], "Failed 00120 UserInterface::text_include")
                 assert(text_area[39] == ["before", 5], "Failed 0130 UserInterface::text_include")
                 assert(text_area[40] == ["text", "40 r s t u v rstuv line4 fourty"], "Failed 00140 UserInterface::text_include")  
    selection  = @user_interface.send(:user_prompt_options, text_area)
                 assert(selection == "1", ":user_prompt_options in test_ring got #{selection} so something about control0100")
    pattern    = @user_interface.send(:user_pattern) if selection == "1" || selection == "2" 
                 assert(pattern == "abc", ":user_pattern in test_ring got #{pattern} so something about control0100")
    text_area  = @text_processor.send(:text_include, text_lines) if selection == "1"                                                      
                 @user_interface.send(:user_display, text_area) if ("1".."5").include?(selection)  
    #            text_area.each { |ta| p ta }
                 puts "\nTest is to include additional lines for pattern in TextProcessor::text_mixer_include" 
                 assert(text_area[1] == ["text", " 1 a b c d e abcde line0 zero start"], "Failed 0150 TextProcessor::text_mixer_include")
                 assert(text_area[3] == ["before", 2], "Failed 0160 TextProcessor::text_mixer_include")
                 assert(text_area[4] == ["text", " 4 m n o p q mnopq line0"], "Failed 0170 TextProcessor::text_mixer_include")
                 assert(text_area[33] == ["before", 2], "Failed 0180 TextProcessor::text_mixer_include")
                 assert(text_area[40] == ["text", "40 r s t u v rstuv line4 fourty"], "Failed 00190 TextProcessor::text_mixer_include")
  end
=begin  
   
  def test_ring0200
    puts "Processing /home/brad/runner/control0200 for test of TextProcessor::text_mixer_exclude"
    ARGV.push("/home/brad/runner/control0200")
    file_name  = @user_interface.send(:user_file_read)
    text_lines = @file_manager.send(:file_directory, "/home/brad/runner/testdata")
    pattern    = @user_interface.send(:user_pattern)
                p "Test pattern is: #{pattern}"  
                assert(pattern == "abc", ":user_pattern in test_ring got #{pattern} so something about the test commands changed")
    text_area  = @text_processor.send(:text_include, text_lines)
    #          text_area.each { |ta| p ta }
                assert(text_area[1] == ["text", " 1 a b c d e abcde line0 zero start"], "Failed 0200 UserInterface::text_include")
                assert(text_area[5] == ["before", 4], "Failed 0210 UserInterface::text_include")
                assert(text_area[36] == ["text", "36 a b c d e abcde zayin"], "Failed 0220 UserInterface::text_include")
                assert(text_area[40] == ["after", 4], "Failed 0230 UserInterface::text_include") 
    while                                                        
    text_area  = @user_interface.send(:user_display, text_area) # Exit is contained in UserInterface::user_prompt_options 
#              text_area.each { |ta| p ta }
                puts "\nTest is to exclude additional lines for pattern in TextProcessor::text_mixer_exclude" 
#                assert(text_area[25] == ["before", 24], "Failed 0240 TextProcessor::text_mixer_exclude")
#                assert(text_area[36] == ["text", "36 a b c d e abcde line3"], "Failed 0250 UserInterface::text_include")
#                assert(text_area[40] == ["after", 4], "Failed 0260 UserInterface::text_include")     
    end
  end

def test_ring0300
    puts "Processing /home/brad/runner/control0300 for test of TextProcessor::text_delete_in"
    ARGV.push("/home/brad/runner/control0300")
    file_name  = @user_interface.send(:user_file_read)
    text_lines = @file_manager.send(:file_directory, "/home/brad/runner/testdata")
    pattern    = @user_interface.send(:user_pattern)
                p "Test pattern is: #{pattern}"  
                assert(pattern == "hijkl line2", ":user_pattern in test_ring got #{pattern} so something about the test commands changed")
    text_area  = @text_processor.send(:text_include, text_lines)
    #          text_area.each { |ta| p ta }
                assert(text_area[14] == ["before", 4], "Failed 0300 UserInterface::text_include")
                assert(text_area[15] == ["text", "15 r s t u v rstuv line1"], "Failed 00310 UserInterface::text_include")
    while                                                      
    text_area  = @user_interface.send(:user_display, text_area)            # Exit is contained in UserInterface::user_prompt_options  
    #          text_area.each { |ta| p ta }
                puts "\nTest is to delete included lines using pattern 'in' in TextProcessor::text_delete_in"
                assert(text_area[10] == ["text", "10 r s t u v rstuv line0 ten"], "Failed 0320 TextProcessor::text_delete_in")
                assert(text_area[24] == ["before", 13], "Failed 0330 TextProcessor::text_delete_in") 
                assert(text_area[25] == ["text", "25 r s t u v rstuv line2"], "Failed 0340 TextProcessor::text_delete_in")
                end
  end
 
  def test_ring0400
    puts "Processing /home/brad/runner/control0400 for test of TextProcessor::text_delete_ex"
    ARGV.push("/home/brad/runner/control0400")
    file_name  = @user_interface.send(:user_file_read)
    text_lines = @file_manager.send(:file_directory, "/home/brad/runner/testdata")
    pattern    = @user_interface.send(:user_pattern)
                p "Test pattern is: #{pattern}"  
                assert(pattern == "in", ":user_pattern in test_ring got #{pattern} so something about the test commands changed")
    text_area  = @text_processor.send(:text_include, text_lines)
    #          text_area.each { |ta| p ta }
                assert(text_area[14] == ["before", 4], "Failed 0400 UserInterface::text_include")
                assert(text_area[15] == ["text", "15 r s t u v rstuv line1"], "Failed 00410 UserInterface::text_include")
    while                                                      
    text_area  = @user_interface.send(:user_display, text_area)            # Exit is contained in UserInterface::user_prompt_options  
    #          text_area.each { |ta| p ta }
                puts "\nTest is to delete excluded lines using pattern 'in' in TextProcessor::text_delete_ex"
                assert(text_area[10] == ["text", "10 r s t u v rstuv line0 ten"], "Failed 0420 TextProcessor::text_delete_ex")
                assert(text_area[24] == ["before", 13], "Failed 0430 TextProcessor::text_include") 
                assert(text_area[25] == ["text", "25 r s t u v rstuv line2"], "Failed 0440 TextProcessor::text_delete_ex")
                end
  end
  
  def test_ring0010
    puts "Processing /home/brad/runner/control0010 for test of TextProcessor::text_mixer_rdin"
    ARGV.push("/home/brad/runner/control0010")
    file_name  = @user_interface.send(:user_file_read)
    text_lines = @file_manager.send(:file_directory, "/home/brad/runner/testdata")
    pattern    = @user_interface.send(:user_pattern)
                p "Test pattern is: #{pattern}"  
                assert(pattern == "rs", ":user_pattern in test_ring got #{pattern} so something about the test commands changed")
    text_area  = @text_processor.send(:text_include, text_lines)
    #          text_area.each { |ta| p ta }
                assert(text_area[14] == ["before", 4], "Failed 0010 UserInterface::text_include")
                assert(text_area[15] == ["text", "15 r s t u v rstuv line1"], "Failed 00020 UserInterface::text_include")
    while                                                      
    text_area  = @user_interface.send(:user_display, text_area)            # Exit is contained in UserInterface::user_prompt_options  
    #          text_area.each { |ta| p ta }
                puts "\nTest is to delete included lines from 11 to 24 using pattern 'rs' in TextProcessor::text_mixer_rdin"
                assert(text_area[10] == ["text", "10 r s t u v rstuv line0 ten"], "Failed 0030 TextProcessor::text_mixer_rdin")
                assert(text_area[24] == ["before", 13], "Failed 0040 TextProcessor::text_mixer_rdin") # 13 because it deletes 2
                assert(text_area[25] == ["text", "25 r s t u v rstuv line2"], "Failed 0050 TextProcessor::text_mixer_rdin")
                end
  end

  def test_ring0100
    puts "Processing /home/brad/runner/control0100 for test of TextProcessor::text_mixer_rdex"
    ARGV.push("/home/brad/runner/control0100")
    file_name  = @user_interface.send(:user_file_read)
    text_lines = @file_manager.send(:file_directory, "/home/brad/runner/testdata")
    pattern    = @user_interface.send(:user_pattern)
                p "Test pattern is: #{pattern}"  
                assert(pattern == "m n", ":user_pattern in test_ring got #{pattern} so something about the test commands changed")
    text_area  = @text_processor.send(:text_include, text_lines)
    #          text_area.each { |ta| p ta }
                assert(text_area[18] == ["before", 4], "Failed 0100 UserInterface::text_include")
                assert(text_area[19] == ["text", "19 m n o p q mnopq line1"], "Failed 00110 UserInterface::text_include")
                assert(text_area[40] == ["after", 1], "Failed 00120 UserInterface::text_include")
    while                                                        
    text_area  = @user_interface.send(:user_display, text_area) # Exit is contained in UserInterface::user_prompt_options          
    #          text_area.each { |ta| p ta }
                puts "\nTest is to delete excluded lines from 9 to 26 using pattern 'm n' in TextProcessor::text_mixer_rdex"
                assert(text_area[8] == ["before", 4], "Failed 0130 TextProcessor::text_mixer_rdex")
                assert(text_area[14] == ["text", "14 m n o p q mnopq line1"], "Failed 00140 TextProcessor::text_mixer_rdex")
                assert(text_area[19] == ["text", "19 m n o p q mnopq line1"], "Failed 00150 TextProcessor::text_mixer_rdex")
                assert(text_area[24] == ["text", "24 m n o p q mnopq line2"], "Failed 00160 TextProcessor::text_mixer_rdex")
                assert(text_area[28] == ["before", 2], "Failed 0170 TextProcessor::text_mixer_rdex")
                assert(text_area[39] == ["text", "39 m n o p q mnopq line3"], "Failed 0180 TextProcessor::text_mixer_rdex")
                assert(text_area[40] == ["after", 1], "Failed 0190 TextProcessor::text_mixer_rdex")  
    end
  end
=end
end