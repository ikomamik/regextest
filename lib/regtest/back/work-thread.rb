# encoding: utf-8

# NOT USED AT PRESENT

require "pp"
require "thread"

class Regtest::Back::WorkThread
  def initialize(thread_id, initial_data = nil)
    @thread_id = thread_id
    @data = initial_data
    @r_queue = Queue.new
    @s_queue = Queue.new
    @proc = nil
  end
  
  attr_reader :thread_id
  
  # Set procedure
  def run(&proc)
    @proc = proc
    @thread = Thread.new {
      Thread.abort_on_exception = true
      @proc.call(@data)
    }
  end
  
  # Request data to child thread (executed in parent thread)
  def request(data)
    @r_queue.push(data)
  end
  
  # Indicate data from parent thread (executed in child thread)
  def indicate
    @r_queue.pop
  end
  
  # Respond data to parent thread (executed in child thread)
  def respond(data)
    @s_queue.push(data)
  end
  
  # Confirm data from child thread (executed in parent thread)
  def confirm
    @s_queue.pop
  end
  
  # Wait to start (executed in child thread)
  def wait
    data = indicate
    raise ("invalid wait. received data is #{data}") if(data != :THR_CMD_START)
  end
  
  # Start child's thread (executed in parent thread)
  def start
    request(:THR_CMD_START)
  end
  
  # Terminate child's thread (executed in parent thread)
  def terminate
    request(:THR_CMD_TERMINATE)
    @thread.join
  end
  
  # Exit thread (executed in child thread)
  def exit
    respond(:THR_CMD_EXIT)
  end
  
  def exit?(data)
    data == :THR_CMD_EXIT
  end
end

# Test suite (execute when this file is specified in command line)
if __FILE__ == $0
  Thread.abort_on_exception = true
  
  thread_num = 3
  threads = []
  data = [[[0,1],[0,1],[0,2]],[[0,1,2],[0,1],[0,1]], [[1],[1],[0]]]
  thread_num.times do | i |
    thread_obj = Regtest::Back::WorkThread.new(i, data[i])
    thread_obj.run { | param |
      while((command = thread_obj.indicate) != :THR_CMD_TERMINATE)
        puts "get command #{command}"
        reply = param.shift
        thread_obj.respond(reply)
      end
      puts "terminate thread"
    }
    threads << thread_obj
  end
  pp threads
  data[0].size.times do
    result = nil
    threads.each do | thread |
      thread.request("do something #{thread}")
      reply = thread.confirm
      if(result == nil)
        result = reply
      else
        result &= reply
      end
    end
    puts "result is #{result}"
  end

  threads.each do | thread |
    thread.terminate
  end
  
  pp threads

end


