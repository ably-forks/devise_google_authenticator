class FooController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    head :ok
  end
end
