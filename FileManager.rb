class FileManager
  
  def initialization

    @current_directory = "" 
  end
  
  # set up the data collection
  def file_get_initialization(structure = ENV["HOME"])                # this is linux specific for now
    @file_information = {}                                            # {"/directory"=>["file"], "/directory/directory"=>["file", "file"]
    files = [] 
    directory = ""
    directories = []                                                  
    things = structure.split('/')
    things.each do |thing|
      if thing == ""
        directories.push("/root")
      else
        directory = "#{directory}/#{thing}" 
        @current_directory = directory
        directories.push("#{directory}") if File.directory?("#{directory}")
      end
    end 
    return directories
  end
    
  def file_get_files(directories) 
    directory = ""
    files = []
    directories.each do |directory| 
      unless directory == "/root"
        Dir.chdir("#{directory}")  
        Dir.foreach("#{directory}") do |d|  
          files.push(d) unless d == "." || d == ".." 
        end
        @file_information.store(directory, files)
        files = []
      end
    end
    return @file_information
  end
      
  def file_get_more_information(directory) 
    @files = []
    @file_information = {}                                            # {"/directory"=>["file"], "/directory/directory"=>["file", "file"]
    directory = "#{@current_directory}/#{directory}" unless @current_directory == ""
    @current_directory = directory                                                    
    Dir.chdir("#{directory}")                                      
    Dir.foreach("#{directory}") { |d| @files.push(d) unless d == "." || d == ".." }
    @file_information.store(directory, @files)
    @files = []
    return @file_information
  end
  
  def file_open(file, mode = "r")
    handle = File.open("#{file}","#{mode}")
    text_lines = {}
    file_in = handle.readlines
    file_in.each_with_index do |line, line_num|
      text_lines[line_num] = line.chomp
    end
    return text_lines
  end

# Writes any given file
  def file_write(file, text_area, mode = "w") 
    if File.writable?(file)
      handle = File.open("#{file}","#{mode}")
      text_area.each_pair do |index,text_paired|  
        if text_paired[0] == "text" 
          handle.write("#{text_paired[1]}\n") 
        end
      end
    else
      puts "Not authorized to write in the folder"
      return false
    end
#    file_close(file)
  end

  def file_close(file)
    @handle.close
  end
  
  # Keeps the current working file available
  # Currently file history is only one deep
  def file_history_push(file)
    file_history = $file_history.to_h
    file_history.each_pair do |index, file_name|
      if file_name == ""
        file_name = file
        $file_history["#{index}"] = "#{file_name}"
        break
      end
    end
  end
  
  # Not in use
  # Needs to be tested
  def file_history_pop(file)
    file_history = $file_history.to_h
    current_history = file_history.pop
    file_history.each_pair do |index, file_name|
      if file_name == current_history
        $file_history.delete_field("#{index}")
        break
      end
    end
  end
  
  # lots of possible uses for this but right now current is current
  def file_history_current
    file_history = $file_history.to_h
    file_history.each_pair do |index, file_name|
      return file_name unless file_name == ""
    end
  end
  # A file directory has been presented and a selection made.
  # * Now it is necessary to determine if the selection is a file or another directory.
  # * This method runs recursively until a file is the selection.
  # * It then records the file in history and returns the file name.
  def file_directory(selection)
    while File.directory?(selection)
      @file_information = file_get_more_information(selection) 
      selection = file_selection(@file_information)
      unless File.directory?(selection)
        break
      end
    end
    if File.directory?(selection)
      @file_information.each do |directory,files|
        files.each { |file| @file = "#{directory}/#{file.to_s}" if file == selection }
      end
    else
      @file = selection
    end
    file_history_push(@file)                                                # store it 
    text_lines = file_open(@file, "r")                                      # open for read
    return text_lines
  end  
  
  def file_selection(file_information)
    key        = "root"                                                    # linux support only for now
    file_break = ""                                                        # save for "break"
    index      = 0                                                          # for user selection
    number    = 0                                                          # for selection from table  
    ui        = {} 
    # build display for user selection
    file_information.each_pair do |directory, files|
      if files.length > 1
        ui.store(index, directory)                                          # the internal UI
        puts "Now in directory: #{directory}" 
        files.each do |file| 
          unless file.start_with?(".")
            if File.directory?(file)
              puts "#{index} #{file}"
            else
              puts "  #{index} #{file}"
            end
            ui.store(index, file) 
            index += 1
          end
        end
      end
    end
    unless $mode == "test"                                                        # global test switch
      ARGF.each_line do |selection|                                                    
        number = selection.chomp!.to_i
        break if (0..index).include?(number.to_i)                            # index reused from above  
      end
      file_name = ui[number]                                                  # get selection from UI table 
    else
      file = ARGF.readline
      @selection = file.chomp! 
      number = selection.chomp!.to_i
      file_name = ui[number]                                                  # get selection from UI table 
    end
  end
end # class FileManager