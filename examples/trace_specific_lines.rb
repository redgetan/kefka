set_trace_func proc { |event, file, line, id, binding, classname|
   printf "%8s %s:%-2d %10s %8s\n", event, file, line, id, classname
   set_trace_func nil if line == 10
}

def fuck
  x = 1
  x = x + 3

  (1..10).each do |x|
    x
  end

end

fuck


