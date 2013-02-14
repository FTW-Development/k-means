# parameters
k = 3
number_of_points = 10000
delta = 0.001
plot_on = true

require './k-means.rb'

points = []
number_of_points.times do
  points << Point2D.new(10*rand()-5.0, 10*rand()-5.0)
end

clusters = k_means points, k, delta, plot_on

clusters.each_with_index do |cluster, index|
  puts "#{ cluster.center.to_s }\t#{ index }"
end

cluster_plot_2D clusters, "#{k}-final" if plot_on
