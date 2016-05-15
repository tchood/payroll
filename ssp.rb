#Statutory sick pay calculator
class SSPCalculator
	DAY = 24 * 60 * 60
	attr_reader :weekly_rate
	
	def initialize (weekly_rate)
		@weekly_rate = weekly_rate
	end

	def self.qualifying_days(from_date, to_date, working_pattern = (1..5))
		 date = from_date
		 days = 0
		 while date <= to_date
		 	 days += 1 if working_pattern.include? date.wday
		   date += DAY
		 end
		 return days
	end

	def self.days_between(from_date, to_date)
		self.qualifying_days(from_date, to_date, (0..6))
	end

	def self.continuous?(from_date, to_date)
		print "#{from_date} and #{to_date} "
		qualifying_days(from_date,to_date,(0..6)) == 2
	end

end

class Absences
	DAY = 24 * 60 * 60
	attr_accessor :absences
	attr_accessor :grouped_absences

	def initialize
		@absences = []
		@grouped_absences = []
	end

	def add (type, start_date, end_date)
		absences.select {|absence| absence[:type]==type}.each do |absence|
			raise 'Start date must be or or before end date' if start_date > end_date
			raise 'Cannot add overlapping absence of same type' if start_date <= absence[:start_date] and end_date >= absence[:start_date]
			raise 'Cannot add overlapping absence of same type' if start_date >= absence[:start_date] and start_date <= absence[:end_date]
		end
		absences << {type: type, start_date: start_date, end_date: end_date, piw_number: nil}
	end

	def grouped_absences (type)
		working_copy = deep_copy(of_type(type))
		subject_index, test_index = 0, 1
		while test_index < working_copy.count
			puts "Comparing (#{subject_index}) dates #{working_copy[subject_index][:end_date]} and (#{test_index}) #{working_copy[test_index][:start_date]}"
			while are_continuous?(working_copy[subject_index],working_copy[test_index])
				puts "Are continuous"
				working_copy[subject_index][:end_date] = working_copy[test_index][:end_date]
				working_copy.delete_at test_index
				test_index +=1
			end
			subject_index +=1; test_index +=1
		end
		return working_copy
	end

	def deep_copy(array)
			array.collect {|item| item.dup}
	end

	def are_continuous?(absence_a, absence_b)
		return nil if absence_a.nil? || absence_b.nil?
		SSPCalculator.continuous?(absence_a[:end_date], absence_b[:start_date])
	end
	
		# group = []
		# absence_no = 0
		# while absence_no < absences_of_type.count - 1
		# 	puts "Looking at #{absences_of_type[absence_no]}"
		# 	continuous_absence = absences_of_type[absence_no].dup
		# 	if SSPCalculator.days_between(absences_of_type[absence_no][:end_date], absences_of_type[absence_no+1][:start_date]) == 2
		# 		continuous_absence[:end_date] = absences_of_type[absence_no+1][:end_date].dup
		# 	end
		# 	group << continuous_absence
		# 	absence_no +=1
		# end
		# return group.sort! {|a,b| a[:start_date] <=> b[:start_date]}

	def of_type (type)
		absences.select {|absence| absence[:type]==type}.sort! {|a,b| a[:start_date] <=> b[:start_date]}
	end


	def identify_piws
		piws = []
		sickness_absences = grouped_absences(:sickness)
		puts "Grouped absences for PIWS: #{sickness_absences}"
		puts "Looking at : #{grouped_absences(:sickness)}"
		sickness_absences.each do |absence|
			puts "Now looking at #{absence} and determining days in period:"
			days_in_period = SSPCalculator.days_between(absence[:start_date], absence[:end_date])
			puts days_in_period
			piws << absence if days_in_period >= 4
		end
	end

end


DAY = 24 * 60 * 60


today = Time.new(2015,7, 1)
before = Time.new(2015,6,29)
ssp = SSPCalculator.new(86.15)
absence = Absences.new
absence.add :sickness, Time.new(2015,12,28), Time.new(2016,01,05)
absence.add :sickness, Time.new(2016,01,06), Time.new(2016,02,03)
absence.add :leave, Time.new(2016,03,02), Time.new(2016,03,07)
absence.add :sickness, Time.new(2016,03,31), Time.new(2016,04,03)
absence.add :sickness, Time.new(2016,04,05), Time.new(2016,04,05)
absence.add :sickness, Time.new(2016,04,06), Time.new(2016,04,12)
absence.add :sickness, Time.new(2016,04,15), Time.new(2016,04,19)

puts "Sorted:"
puts absence.absences.sort! {|a,b| a[:start_date] <=> b[:start_date]}
#puts "Grouped sickness:"
#puts absence.grouped_absences(:sickness)
puts "Grouped sickness:"
puts absence.grouped_absences(:sickness)
puts "Grouped sickness:"
puts absence.grouped_absences(:sickness)
puts "Standard absences"
puts absence.absences
puts "Absences of type sickness"
puts absence.of_type(:sickness)

# test_array = %w(a b c d e)
# new_array = absence.deep_copy(test_array)
# puts "Test Array: #{test_array}"
# puts "New Array: #{new_array}"
# new_array[1] = 'z'
# puts "Test Array: #{test_array}"
# puts "New Array: #{new_array}"