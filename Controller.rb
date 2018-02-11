#!/usr/bin/ruby

class Controller
  
  # https://codereview.stackexchange.com/questions/10312/communication-between-two-classes-in-ruby
  
  attr_accessor :handle, :this_one, :text_area

  def initialize
    @file_process = FileManager.new
    @user_process = UserInterface.new
    @text_process = TextProcessor.new
  end

  def start
    @file_process.file_open()
#    @file_process.file_print_all()
    @user_process.user_initiation()
    @user_process.user_exclusion()
    @text_process.text_handler(@file_process.handle, @user_process.this_one, @user_process.these_lines, @user_process.text_area)
    @user_process.user_display(text_area)
    @user_process.user_inclusion()
    @text_process.text_handler(@file_process.handle, @user_process.this_one, @user_process.these_lines, @user_process.text_area)
    @user_process.user_display(text_area)
    # @file_process.file_print(@text_process.lines_out)
    @file_process.file_close()
  end

end # class Controller
