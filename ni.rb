class Round  #duplicated from test.rb - remove
	def self.down (value, exp = 0)
		multiplier = 10 ** exp
		((value * multiplier).floor).to_f/multiplier.to_f
	end

	def self.up (value, exp = 0)
		multiplier = 10 ** exp
		((value * multiplier).ceil).to_f/multiplier.to_f
	end
end

class NICalculator
	attr_reader :year_ending, :category_letter, :annual_periods, :pay_frequency, :pro_rata_thresholds
	
	def initialize (args)
		@year_ending = args[:year_ending]
		@category_letter = args[:category_letter]
		@annual_periods = {'W' => 52, 'M' => 12}[args[:annual_periods]] || args[:annual_periods]
		@pay_frequency = args[:pay_frequency] || 1
	end

	def thresholds
		case year_ending
		when '2017'
			{ZERO: 0, LEL: 5824, PT: 8060, ST: 8112, UEL: 43000, UST: 43000} unless category_letter == 'M'
			{ZERO: 0, LEL: 5824, PT: 8060, ST: 8112, UEL: 43000, UST: 43000}
		end
	end

	def ee_rates
		case year_ending
		when '2017'
			case category_letter
			  when 'A', 'H', 'M'
			  	{ZERO: 0, LEL: 0, PT: 0.12, ST: 0.12, UEL: 0.02, UST: 0.02}
			  when 'B'
			  	{ZERO: 0, LEL: 0, PT: 0.0585, ST: 0.0585, UEL: 0.02, UST: 0.02}
			  when 'C'
			  	{ZERO: 0, LEL: 0, PT: 0, ST: 0, UEL: 0, UST: 0}
			  when 'J', 'Z'
			  	{ZERO: 0, LEL: 0, PT: 0.02, ST: 0.02, UEL: 0.02, UST: 0.02}
			end
		end
	end

	def er_rates
		case year_ending
		when '2017'
			case category_letter
		 	  when 'A', 'B', 'C', 'J'
				  {ZERO:0, LEL: 0, PT: 0, ST: 0.138, UEL: 0.138, UST: 0.138}
			  when 'H','M','Z'
			  	{ZERO:0, LEL: 0, PT: 0, ST: 0, UEL: 0.138, UST: 0.138}
			end
		end
	end

	def pay_at_tier(gross_pay, tier=0)
		if tier == pro_rata_thresholds.count - 1 
			[gross_pay - pro_rata_thresholds[tier], 0].max.round(2)
		else
			[(gross_pay - pro_rata_thresholds[tier]), 0].max.round(2) - [(gross_pay - pro_rata_thresholds[tier+1]), 0].max.round(2)
		end
	end

	def tiered_pay(gross_pay)
		(0...pro_rata_thresholds.count).collect do |tier|
			pay_at_tier(gross_pay, tier)
		end
	end

	def pro_rata_thresholds
		thresholds.collect do |label, threshold|
			pro_rata_threshold(label, threshold)
		end
	end

	def pro_rata_threshold (label, threshold)
		result = (threshold * pay_frequency / annual_periods.to_f)
		label == :LEL || pay_frequency > 1 ? result.ceil : result.round
	end

	def ees_ni_payable(gross_pay)
		ni_payable(gross_pay, ee_rates)
	end

	def ers_ni_payable(gross_pay)
		ni_payable(gross_pay, er_rates)
	end

	def ni_payable(gross_pay, rates)
		total = 0
		(0...rates.count).each do |tier|
			total += ni_rounding(pay_at_tier(gross_pay, tier) * rates.values[tier])
			#puts "Calculating pay at tier #{tier}: #{pay_at_tier(gross_pay, tier)} at rate #{rates.values[tier]}: Cumulative total: #{total}"
		end
		ni_rounding(total)
	end

	def ni_rounding(n)
		third_place = ((Round.down(n,3) - Round.down(n,2))*1000).round
		third_place <= 5 ? Round.down(n,2) : Round.up(n,2)
	end
end
