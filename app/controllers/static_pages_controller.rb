class StaticPagesController < ApplicationController
  def home
  end

  def help
  end

  def demo
  end

  def home_en
  end

  def help_en
  end

  def demo_en
  end

  def demo_page1
    render :layout => false
  end

  def demo_page2
    render :layout => false
  end

end
