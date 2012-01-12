require 'pry-exception_explorer'

# default is to capture all exceptions that bubble to the top
PryExceptionExplorer.intercept { true }

module PryExceptionExplorer

  def self.wrap
    old_enabled, old_wrap_active = enabled, wrap_active
    self.enabled     = true
    self.wrap_active = true
    yield
  rescue Exception => ex
    if ex.should_capture?
      enter_exception(ex)
    else
      raise ex
    end
  ensure
    self.enabled     = old_enabled
    self.wrap_active = old_wrap_active
  end
end

