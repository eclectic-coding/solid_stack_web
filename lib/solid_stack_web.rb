require "solid_stack_web/version"
require "solid_stack_web/engine"

module SolidStackWeb
  class << self
    attr_writer :page_size, :connects_to

    def page_size
      @page_size || 25
    end

    def connects_to
      @connects_to
    end

    def configure
      yield self
    end

    def authenticate(&block)
      @authenticate = block if block_given?
      @authenticate
    end
  end
end
