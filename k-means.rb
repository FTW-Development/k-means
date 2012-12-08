require 'gnuplot'

class Point
  attr_accessor :coords
  def initialize coords
    @coords = coords
  end
  def distance_to point
    Math.sqrt( @coords.keys.inject(0) { |sum, key| sum + (@coords[key] - point.coords[key])**2 } )
  end
  def to_s
    "#{coords.values.join(", ")}"
  end
end


class Point2D < Point
  def initialize x, y
    @coords = {'x' => x, 'y'=> y}
  end
  def x
    @coords['x']
  end
  def x= i
    @coords['x'] = i
  end
  def y
    @coords['y']
  end
  def y= i
    @coords['y'] = i
  end
end

class Cluster
  attr_reader :points, :center, :moved
  def initialize center
    @center = center
    @points = []
    @moved = true
  end
  def add_point point
    @points << point
  end
  def update_center delta = 0.001
    @moved = false
    averages = {}
    @center.coords.keys.each do |key|
      averages[key] = @points.inject(0.0) {|sum, point| sum + point.coords[key]} / @points.length unless @points.length == 0
    end
    unless Point.new(averages).distance_to(@center) < delta
      @center = Point.new(averages)
      @moved = true
    end    
  end
  def clear_points
    @points = []
  end
  def distance_to point
    point.distance_to @center
  end
  def number_of_points
    @points.length
  end
  def to_s
    "#{@center.to_s}: #{number_of_points} points, cost: #{cost}"
  end
  def cost
    @points.inject(0) { |sum, point| sum + point.distance_to(@center) }
  end
end

def k_means points, k = 5, delta = 0.001
  infinity = 1.0/0
  clusters = []
  k = points.length if points.length < k
  k.times do 
    clusters << Cluster.new(points.sample)
  end
  iterations = 0

  while (clusters.inject(false) {|result, center| result || center.moved})
 
    clusters.each { |cluster| cluster.clear_points }

    points.each do |point|
      shortest = infinity
      cluster_found = nil
      clusters.each do |cluster|
        distance = cluster.distance_to(point)
        if distance < shortest
          cluster_found = cluster
          shortest = distance
        end 
      end
      cluster_found.add_point point unless cluster_found.nil?
    end

    clusters.delete_if { |cluster| cluster.number_of_points == 0 }
    clusters.each { |cluster| cluster.update_center delta}
    iterations += 1
    cluster_plot_2D clusters, "#{k}-%05d" % iterations
    # puts iterations
  end

  puts iterations
  clusters
end

def cluster_plot_2D clusters, seq = 1
  Gnuplot.open do |gp|
    # Start a new plot
    Gnuplot::Plot.new(gp) do |plot|
      plot.terminal "png"
      plot.output File.expand_path("../clusters-#{seq}.png", __FILE__)
      plot.title "Random noise"

      # Plot each cluster's points
      clusters.each do |cluster|
        # Collect all x and y coords for this cluster
        x = cluster.points.collect {|p| p.x }
        y = cluster.points.collect {|p| p.y }

        # Plot w/o a title (clutters things up)
        plot.data << Gnuplot::DataSet.new([x,y]) do |ds|
          ds.notitle
        end
      end
      x = clusters.collect {|p| p.center.coords['x'] }
      y = clusters.collect {|p| p.center.coords['y'] }
      plot.data << Gnuplot::DataSet.new([x,y]) do |ds|
        ds.notitle
      end
    end
  end
end