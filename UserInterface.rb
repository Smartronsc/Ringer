
class UserInterface

  # use assoc(line number) for line commands
  def initialize
    @file_manager  = FileManager.new 
    @text_processor = TextProcessor.new
  end
  
  def user_prompt(prompt)
    puts prompt                                                              # initial prompt 
    selection = ""
    ARGF.each_line do |file|
      @file = file.chomp!
      prompt = "Enter File or directory"                                      # follow on prompt 
      if @file == ""
        # initial load of $file_information dealing with / (root) and /home
        directories = @file_manager.send(:file_get_initialization)
         p "user_prompt directories #{directories}"
        file_information = @file_manager.send(:file_get_files, directories) 
         p "user_prompt file_information #{file_information}"
        selection = user_selection(file_information)
        file_information.each do |key,value| 
          value.each { |v| selection = "#{key}/#{v.to_s}" if v == selection } unless value == ""
        end
      end

      unless selection == nil
      while File.directory?(selection)
        # p "selection #{selection}"
        directories = [selection]
        # p "directories #{directories}"
        @file_manager.send(:file_get_files, directories) 
        p "File.directory file_information #{file_information}"
        selection = user_selection(file_information)
        p "File.directory selection #{selection}"
          if File.directory?(selection)
          puts "File selected is: #{selection}"
          break
        end
      end
      end

      @file_manager.send(:file_history_push, @file)                         # store it for UserInterface class  
    end
    user_pattern                                                            # update search_history
    arguments = [@file, "r"]
    text_lines = @file_manager.send(:file_open, *arguments)                 # initial open
    @text_processor.send(:text_exclude, text_lines)                         # initial exclude                          
  end
  
  def user_selection(file_information)
    key        = "root"                                                     # linux support only for now
    file_break = ""                                                         # save for "break"
    index      = 0                                                          # for user selection
    number     = 0                                                          # for selection from table  
    ui         = {} 
    # build display for user selection
    file_information.each_pair do |directory, files| 
      if files.length > 1
        puts "#{index} #{directory}"                                          # the actual UI
        ui.store(index, directory)                                            # the internal UI
        files.each do |file| 
          puts "#{index} #{file}" 
          ui.store(index, file) 
          index += 1
        end
      end
    end
    # parse user selection
    ARGF.each_line do |selection|                                          
      number = selection.chomp!.to_i
      break if (0..index).include?(number.to_i)                             # index reused from above  
    end
    selection = ui[number]                                                  # get selection from UI table 
end

def user_get_file
    action = ":file_get_initialization"
    @file_manager.send(action) 
    puts prompt 
    ARGF.each_line do |file|
      @file = file.chomp!
      if @file == "" 
        @file = user_selection
        if File.directory?(@file)
          @file_manager.send(:file_get_information, @file) 
          @file = user_selection
        end
      end
      @file_manager.send(:file_history_push, @file)                          # store it for UserInterface class 
      break                                                                  # just one file at a time for now
    end
    user_pattern                                                            # update search_history
    arguments = [@file, "r"]
    text_lines = @file_manager.send(:file_open, *arguments)                  # initial open
    @text_processor.send(:text_exclude, text_lines)                          # initial exclude    
  end
end # class UserInterface
