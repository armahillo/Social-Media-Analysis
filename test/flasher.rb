#!/usr/bin/env ruby

# h/t to Jay Fields for this solution
# http://blog.jayfields.com/2007/11/ruby-testing-private-methods.html
# This overrides Class to make private methods temporarily public for testing.

class Class
  def publicize_methods
    saved_private_instance_methods = self.private_instance_methods
    self.class_eval { public *saved_private_instance_methods }
    yield
    self.class_eval { private *saved_private_instance_methods }
  end
end
