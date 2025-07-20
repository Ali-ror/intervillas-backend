# encoding: UTF-8

class FallbackController < ApplicationController

  def dispatch
    logger.debug request.inspect
  end

  def test
    logger.debug request.inspect
  end

end
