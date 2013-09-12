require 'nokogiri'

class MapEquation

	def convert_to_input_format(input_dir,output_file_name)
		#input format is PAJEK
		num_vertices = 1#indexed from 1
		num_edges = 1#indexed from 1

		vertices_list = Hash.new
		edges_list = Hash.new


		#assumed that this is a follower/following graph.
		Dir.foreach(input_dir) do |item|
			next if item == '.' or item == '..'
			next unless item.include? '.xml'
			#do work on real items
			file = File.open("#{input_dir}/#{item}","r")
			doc = Nokogiri::XML(file.read)
			file.close

			#do the conversion

			#get the base profile name
			prof_name = doc.xpath("profile/name/text()").to_s

			#add the base node to the list
			profile_node_num = num_vertices
			vertices_list.merge {"#{profile_node_num}" => prof_name}
			num_vertices = num_vertices + 1

			#loop through followers
			doc.xpath("profile/name/followers/follower_name").each do |name_node|
				name = name_node.xpath('./text()')
				next if name == nil or name.trim == '' 
				unless vertices_list.include? name.trim
					vertices_list.merge {"#{num_vertices}" => name}
					num_vertices = num_vertices + 1
				end
				edges_list.merge {"#{num_edges}" => [num_vertices,profile_node_num]}
				num_edges = num_edges + 1
			end

			#loop through followed
			doc.xpath("profile/name/followers/following_name").each do |name_node|
				name = name_node.xpath('./text()')
				next if name == nil or name.trim == ''
				unless vertices_list.include? name.trim
					vertices_list.merge {"#{num_vertices}" => name}
					num_vertices = num_vertices + 1
				end
				edges_list.merge {"#{num_edges}" => [profile_node_num,num_vertices]}
				num_edges = num_edges + 1
			end

		end

	end



end

class CommandLineInterface

	def initialize
		display_options
	end

	def display_options
		puts 'choose an option'
		puts '1.	convert to network format'
		convert_to_net_format
	end

	def convert_to_net_format
		me = MapEquation.new
		input_file_name = STDIN.gets("please input an input file name").strip.trim
		output_file_name = STDIN.gets("please input an output file name").strip.trim
		me.convert_to_input_format(input_file_name,output_file_name)
	end
end

me = MapEquation.new
convert_to_input_format('/vol/projects/kris/OpenRep/Iain/results/community_follower_dataset',
	'/home/rialto1/walkeriain/2013/Honours/Infomap-0.11.5/input')

#cli = CommandLineInterface.new