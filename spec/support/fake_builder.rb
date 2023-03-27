# frozen_string_literal: true

class FakeBuilder
  attr_accessor :middlewares

  def initialize(&)
    @middlewares = []
    instance_eval(&) if block_given?
  end

  def use(middleware, *args)
    @middlewares << [middleware, args]
  end
end
