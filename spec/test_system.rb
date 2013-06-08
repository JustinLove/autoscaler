class TestSystem
  def initialize(pending)
    @pending = pending
  end

  def workers; 0; end
  def queued; @pending; end
  def scheduled; 0; end
  def retrying; 0; end
end
