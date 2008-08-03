
HotCocoa::Mappings.map :view => :NSView do

  defaults :frame => DefaultEmptyRect,
           :layout => {}

  constant :auto_resize, {
    :none   => NSViewNotSizable,
    :width  => NSViewWidthSizable,
    :height => NSViewHeightSizable,
    :min_x  => NSViewMinXMargin,
    :min_y  => NSViewMinYMargin,
    :max_x  => NSViewMaxXMargin,
    :max_y  => NSViewMaxYMargin
  }
  
  constant :border, {
    :none           => NSNoBorder,
    :line           => NSLineBorder,
    :bezel          => NSBezelBorder,
    :groove         => NSGrooveBorder
  }

  def init_with_options(view, options)
    view.initWithFrame options.delete(:frame)
  end
  
  custom_methods do

    def auto_resize=(value)
      setAutoresizingMask(value)
    end
    
    def <<(view)
      addSubview(view)
    end
    
    def layout=(options)
      @layout = LayoutOptions.new(self, options)
      @layout.update_layout_views!
    end
    
    def layout
      @layout
    end

  end
    
end