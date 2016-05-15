require 'date'

class Calendar
	attr_accessor :absences, :sort_by_start

	def initialize
		@absences = []
	end

	def add (type, start_date, end_date)
		raise 'Start date must be or or before end date' if start_date > end_date
		absences.select {|absence| absence[:type]==type}.each do |absence|
			 absence_range = (absence[:start_date]..absence[:end_date])
			 raise 'Overlapping absence' if absence_range.include? start_date or absence_range.include? end_date
		end
		absences << {type: type, start_date: start_date, end_date: end_date}
	end

	def sort_by_start
			absences.sort! {|a,b| a[:start_date] <=> b[:start_date]}
	end

	def consolidate
		absences.sort_by_start
		prev = absences.first
		absences.slice_before { |e| 
			prev, prev2 = e, prev
			prev2[:end_date] + 1 != e[:start_date]
			}.collect {|r| r}
	end

end




a = Date.parse("2016-04-16")

b, c, cd, d, e, f, g = a+10, a+15, a+17, a+20, a+21, a+24, a+25
a1 = Date.parse("2016-04-16")

cal = Calendar.new
cal.add :sickness, a, b
cal.add :sickness, c, d
#cal.add :leave, cd, d
cal.add :sickness, e, f
cal.add :sickness, g, g

puts cal.absences
puts "Consolidated:"
p cal.consolidate

puts a+1 != a1

date_range = (a..f)
p date_range
puts date_range.include? g