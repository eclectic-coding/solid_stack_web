module RequestHelpers
  def self.included(base)
    base.let(:engine_root) { "/solid_stack" }
  end
end

RSpec.configure do |config|
  config.include RequestHelpers, type: :request
end
