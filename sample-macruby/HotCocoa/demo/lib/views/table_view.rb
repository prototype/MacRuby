class TableView

  def self.description 
    "Table Views"
  end
  
  def self.create
    layout_view :frame => [0, 0, 0, 0], :layout => {:expand => [:width, :height]}, :margin => 0, :spacing => 0 do |view|
      view << scroll_view(:layout => {:expand => [:width, :height]}) do |scroll|
        scroll << table_view( 
          :columns => [
            column(:id => :first_name, :text => "First"), 
            column(:id => :last_name, :text => "Last")
            ],
          :data => [
            {:first_name => "Richard", :last_name => "Kilmer"},
            {:first_name => "Chad",    :last_name => "Fowler"}
          ]
        )
      end
    end
  end

  DemoApplication.register(self)
  
end
