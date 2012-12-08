require './k-means.rb'

# parameters
k = 10
number_of_points = 10000
delta = 0.01

points = []
number_of_points.times do 
  points << Point2D.new(10*rand()-5.0, 10*rand()-5.0)
end

clusters = k_means points, k, delta

clusters.each_with_index do |cluster, index| 
  puts "#{cluster.center.to_s}\t#{index}"
end

cluster_plot_2D clusters, "#{k}-final"
