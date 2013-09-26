require 'nokogiri'

class MapEquation

	def convert_profile_to_input_format(input_dir,output_file_name)
		puts 'converting profiles to input format...'

		num_vertices = 1
		num_edges = 1

		vertices_list = Hash.new
		edges_list = Hash.new

		Dir.foreach (input_dir) do |item|
			next if item == '.' or item == '..'
			next unless item.include? '.xml'
			#do work on real items only
				file = File.open("#{input_dir}/#{item}","r")
				doc = Nokogiri::XML(file.read)
				file.close

				#get base profile name
				prof_name = item.gsub(".xml","")
				puts "prof name:#{prof_name}"

				#add the base node to the list
				profile_node_num = num_vertices
				vertices_list[num_vertices] = prof_name
				num_vertices = num_vertices + 1

				#loop through tweets
				doc.xpath("profile/tweets/tweet").each do |tweet_node|				
					tweet_node.xpath("./retweet_names/name").each do |retweet_name_node|						
						name = retweet_name_node.xpath('./text()').to_s
						next if name == nil or name.strip == ''
						unless vertices_list.include? name.strip						
							vertices_list[num_vertices] = name
							num_vertices = num_vertices + 1
						end
						edges_list[num_edges] = [num_vertices,profile_node_num]
						num_edges = num_edges + 1
					end
				end

		end

		#write to file

		
		file = File.open("#{output_file_name}/dataset_vol_3.net","w")
		file.write("*Vertices #{num_vertices}\n")
		vertices_list.each do |key,value|
			file.write("#{key} #{value}\n")
		end

		file.write("*Edges #{num_edges}\n")

		edges_list.each do |key,value|
			file.write("#{value[0]} #{value[1]}\n")
		end

		file.close

	end

	def convert_to_input_format(input_dir,output_file_name)
		puts 'convert to input format'
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
			puts "prof name:#{prof_name}"

			#add the base node to the list
			profile_node_num = num_vertices
			vertices_list[num_vertices] = prof_name
			#vertices_list.merge ({"#{profile_node_num}" => prof_name})
			num_vertices = num_vertices + 1		

			#puts doc.xpath("profile").to_s

			#loop through followers
			doc.xpath("profile/followers/follower_name").each do |name_node|
				name = name_node.xpath('./text()').to_s
				next if name == nil or name.strip == '' 
				unless vertices_list.include? name.strip
					vertices_list[num_vertices] = name
					#vertices_list.merge({"#{num_vertices}" => name})
					num_vertices = num_vertices + 1
				end
				edges_list[num_edges] = [num_vertices,profile_node_num]
				#edges_list.merge( {"#{num_edges}" => [num_vertices,profile_node_num]})
				num_edges = num_edges + 1
			end

			#loop through followed
			doc.xpath("profile/following/following_name").each do |name_node|
				name = name_node.xpath('./text()').to_s
				next if name == nil or name.strip== ''
				unless vertices_list.include? name.strip
					vertices_list[num_vertices] = name
					#vertices_list.merge({"#{num_vertices}" => name})
					num_vertices = num_vertices + 1
				end
				edges_list[num_edges] = [profile_node_num,num_vertices]
				#edges_list.merge ({"#{num_edges}" => [profile_node_num,num_vertices]})
				num_edges = num_edges + 1
			end		
		end

		#write to file.

		file = File.open("#{output_file_name}/profile_tweets.net","w")
		file.write("*Vertices #{num_vertices}\n")
		vertices_list.each do |key,value|
			file.write("#{key} #{value}\n")
		end

		file.write("*Edges #{num_edges}\n")

		edges_list.each do |key,value|
			file.write("#{value[0]} #{value[1]}\n")
		end

		file.close
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
#me.convert_to_input_format('home/rialto1/walkeriain/2013/Honours/temp'#
me.convert_profile_to_input_format('/vol/projects/kris/OpenRep/Iain/results/dataset/vol_3','/vol/projects/kris/OpenRep/Iain/InfoMap/input')
#me.convert_to_input_format('/home/rialto1/walkeriain/2013/Honours/temp/kieran_followers','/home/rialto1/walkeriain/2013/Honours/Infomap-0.11.5/input')
#me.convert_to_input_format('/vol/projects/kris/OpenRep/Iain/results/community_follower_dataset','/home/rialto1/walkeriain/2013/Honours/Infomap-0.11.5/input')

#cli = CommandLineInterface.new