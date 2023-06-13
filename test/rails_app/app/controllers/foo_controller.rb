class FooController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    render :nothing => true
  end
end
