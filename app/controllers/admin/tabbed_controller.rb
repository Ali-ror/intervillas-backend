# encoding: UTF-8

class Admin::TabbedController < AdminController

  layout :choose_layout

private

  def choose_layout
    request.xhr? ? false : 'admin'
  end

end
