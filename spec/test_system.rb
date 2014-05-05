class TestSystem
  def initialize(pending, current = 0)
    @pending = pending
    @current = current
  end

  def workers; @current; end
  def queued; @pending; end
  def scheduled; 0; end
  def retrying; 0; end
end
