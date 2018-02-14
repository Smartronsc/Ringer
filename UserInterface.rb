class UserInterface
   
  require './FileManager.rb'
 
  def user_options(text_area)
    puts <<-DELIMITER
    1. Include additional text
    2. Delete all excluded
    3. Delete all not excluded
      DELIMITER
    selection = gets.chomp              
#    selection = "1"
    case selection
      when "1"
#      puts("Under development, need to mixin the last display with the next")  
      @file_processor = FileManager.new
      current_file = @file_processor.send(:file_history_current)                      # get the current file as it closed 
      @file_processor = FileManager.new
      @file_processor.send(:file_open, current_file)                                  # reopen it
      @text_processor = TextProcessor.new
      @text_processor.send(:text_handler, @handle)                                    # re-read in the lines from the file     
      when "2"
      puts("Not available yet")
             exit
      when "3"
      puts("Not available yet")
             exit
      else
      puts("Exiting")
       exit
    end
  end
 
  # use assoc(line number) for line commands
  def user_file?
#    puts "File to open gem all.rb or other: " 
    puts "File to open /home/brad/git/Ringer/TextProcessor.rb or other: " 
    file = gets.chomp
#    file = "gem all.rb"
    file = "/home/brad/git/Ringer/TextProcessor.rb" if file == ""
#    file = "gem all.rb" if file == nil
    @file_processor = FileManager.new
    @file_processor.send(:file_open, file) 
  end
  # finds non excluded text in the file and excludes it
  def user_exclude?(text_lines) 
    puts "String not to exclude: "
    exclude = gets.chomp
    exclude = 'if /#{Regexp.escape(exclude)}/.match(text)' if exclude == ""
    @text_processor = TextProcessor.new
    @text_processor.send(:text_exclude, exclude, text_lines)
  end
  
 def user_display(text_area)
    puts"======== ====5====1====5====2====5====3====5====4====5====5====5====6====5====7====5====8====5====9====5====0====5====1====5====2====5=="
    text_area.each do |line, action|
      if action[0] == "before" 
        puts "-------- -------------------------------------------------------- #{action[1]} lines excluded ---------------------------------------------------"
      end 
      if action[0] == "text" 
        format = "%08d %-80s" % [line, action[1]]
        puts format
      end
      if action[0] == "after" 
        puts "-------- -------------------------------------------------------- #{action[1]} lines excluded ----------------------------------------------------"
      end 
    end 
    user_options(text_area)
  end


end # class UserInterface