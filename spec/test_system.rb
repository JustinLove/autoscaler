class TestSystem
  def initialize(pending, current = 0)
    @pending = pending
    @current = current
  end

  def workers; @current; end
  def queued; @pending; end
  def scheduled; 0; end
  def retrying; 0; end
  def total_work
    queued + scheduled + retrying + workers
  end
  def any_work?
    queued > 0 || scheduled > 0 || retrying > 0 || workers > 0
  end
end
