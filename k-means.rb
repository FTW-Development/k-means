begin
  require 'gnuplot'
rescue LoadError
  puts "No usable Gnuplot..."
end

class Point
  def initialize(coords)
    @coords = coords
  end
  def distance_to(point)
    Math.sqrt( @coords.keys.inject(0) { |sum, key| sum + (@coords[key] - point.send(key))**2 } )
  end
  def to_s
    "#{@coords.values.join(", ")}"
  end
  def dimensions
    @coords.keys
  end
  def method_missing(m, *args)
    if m.to_s.end_with? '='
      @coords[m.to_s.chop.to_sym]= args.first
    else
      @coords[m]
    end
  end
end

class Point2D < Point
  def initialize(x, y = nil)
    y.nil? ? super(x) : super({x: x, y: y})
  end
end

class Cluster
  attr_reader :center
  def initialize(center)
    @center = center
    @points = []
    @moved = true
  end
  def add_point(point)
    @points << point
  end
  def update_center(delta = 0.001)
    @moved = false
    averages = {}
    @center.dimensions.each do |dimension|
      averages[dimension] =
          @points.inject(0.0) {|sum, point| sum + point.send(dimension)} /
              @points.length unless @points.length == 0
    end
    unless Point.new(averages).distance_to(@center) < delta
      @center = Point.new(averages)
      @moved = true
    end
  end
  def clear_points
    @points = []
  end
  def collect(dimension)
    @points.collect {|p| p.send(dimension) }
  end
  def distance_to(point)
    @center.distance_to point
  end
  def number_of_points
    @points.length
  end
  def to_s
    "#{@center.to_s}: #{number_of_points} points, cost: #{ @points.inject(0) { |sum, point| sum + point.distance_to(@center) }}"
  end
  def moved?
    @moved
  end
end

def k_means (points, k = 5, delta = 0.001, plot_on = false)
  k = points.length if points.length < k
  
  clusters = []
  
  k.times do
    clusters << Cluster.new(points.sample)
  end

  iterations = 0

  while (clusters.any?(&:moved?))

    clusters.each(&:clear_points)

    points.each do |point|
      shortest = Float::INFINITY # requires Ruby 1.9.2 or later
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

    cluster_plot_2D(clusters, "#{k}-%05d" % iterations) if plot_on && points.first.instance_of?(Point2D)
  end

  puts iterations
  clusters
end

def cluster_plot_2D(clusters, seq = 1, title = "Random noise", get_x = 'x', get_y = 'y')
  if defined? Gnuplot
    Gnuplot.open do |gp|
      Gnuplot::Plot.new(gp) do |plot|
        plot.terminal "png"
        plot.output File.expand_path("../outfiles/clusters-#{seq}.png", __FILE__)
        plot.title title

        # Plot each cluster's points
        clusters.each do |cluster|
          # Collect all x and y coords for this cluster
          x = cluster.collect(get_x.to_sym)
          y = cluster.collect(get_y.to_sym)

          # Plot w/o a title (clutters things up)
          plot.data << Gnuplot::DataSet.new([x,y]) do |ds|
            ds.notitle
          end
        end
         # Plot each cluster's centers
        x = clusters.collect {|p| p.center.send(get_x.to_sym) }
        y = clusters.collect {|p| p.center.send(get_y.to_sym) }
        plot.data << Gnuplot::DataSet.new([x,y]) do |ds|
          ds.notitle
        end
      end
    end
  end
end