class Employee
	
	attr_accessor :cum_pay, :cum_tax_liability, :cum_tax_paid

	@@no_of_employees=0

	def initialize (surname, forenames, birthdate)
		@@no_of_employees += 1
		@id = @@no_of_employees
		@surname = surname
		@forenames = forenames
		self.birthdate = birthdate
	end

	def birthdate= (value)
		value.is_a?(Time) ? (@birthdate = value) : (raise 'Invalid birthdate')
	end

	def age(as_at = Time.now)
  	raise 'Date expected in age method' unless as_at.is_a?(Time)
	  as_at.year - @birthdate.year - ((as_at.month > @birthdate.month || (as_at.month == @birthdate.month && as_at.day >= @birthdate.day)) ? 0 : 1)
	end

	def initials(limit=-1)
		@forenames.split(' ',limit).map {|name| name[0]}.reject {|initial| initial==" "}.join
	end

end

class Round
	def self.down (value, exp = 0)
		multiplier = 10 ** exp
		((value * multiplier).floor).to_f/multiplier.to_f
	end

	def self.up (value, exp = 0)
		multiplier = 10 ** exp
		((value * multiplier).ceil).to_f/multiplier.to_f
	end
end

class TaxPeriod

	#attr_reader :c_B1, :c_B2, :c_B3, :c_G, :c_M, :c_R1, :c_R2, :c_R3, :c_R4
	#attr_reader :c_C1, :c_C2, :c_C3, :c_K1, :c_K2, :c_K3
	#attr_reader :c_c1, :c_c2, :c_c3, :c_v1, :c_v2, :c_v3
	attr_reader :n, :year_ending, :periods_in_year, :c_M

	def initialize (year_ending, current_period, periods_in_year)
		#add sense check of periods here
		@year_ending = year_ending
		@n = current_period.to_f
		@periods_in_year = periods_in_year.to_f
		@year_fraction = @n / @periods_in_year
		# Initialise constants depending on year
		case
		when @year_ending == "2015"
			@c_B1 = 0
			@c_B2 = 31865.0
			@c_B3 = 118135.0
			@c_R1 = 0.1
			@c_R2 = 0.2
			@c_R3 = 0.4
			@c_R4 = 0.45
			@c_G = @c_R2
			@c_G1 = @c_R3
			@c_G2 = @c_R4
			@c_M = 0.5
		end

		# Initialise calculated constants for year
		@c_C1 = @c_B1
		@c_C2 = @c_B1 + @c_B2
		@c_C3 = @c_B1 + @c_B2 + @c_B3
		@c_K1 = @c_R1 * @c_B1
		@c_K2 = @c_R1 * @c_B1 + @c_R2 * @c_B2
		@c_K3 = @c_R1 * @c_B1 + @c_R2 * @c_B2 + @c_R3 * @c_B3

		# Initialise calculated weekly thresholds

		@c_c1 = Round.down(@c_C1 * @year_fraction,4)
		@c_c2 = Round.down(@c_C2 * @year_fraction,4)
		@c_c3 = Round.down(@c_C3 * @year_fraction,4)
		@c_v1 = Round.up(@c_c1,0)
		@c_v2 = Round.up(@c_c2,0)
		@c_v3 = Round.up(@c_c3,0)
		@c_k1 = Round.down(@c_K1 * @year_fraction,4)
		@c_k2 = Round.down(@c_K2 * @year_fraction,4)
		@c_k3 = Round.down(@c_K3 * @year_fraction,4)

	end

	def allowance (tax_code_number)
		return 0 if tax_code_number == 0
		quotient, remainder = (tax_code_number - 1).divmod(500)
		remainder +=1
		remainder_allowance = Round.up(((remainder * 10) + 9) / @periods_in_year,2)
		quotient_allowance = quotient * Round.up(500*10 / @periods_in_year, 2)
		puts "Tax code no #{tax_code_number}, quotient #{quotient}, remainder #{remainder}"
		puts "n = #{@n}; remainder_allowance = #{remainder_allowance}; quotient_allowance = #{quotient_allowance}"
		@n * (remainder_allowance + quotient_allowance)
	end

	def taxable_pay (pay, tax_code_number, tax_code_letter)
		case tax_code_letter
		when "BR", "D0", "D1", "D2", "D3", "NT"
			return pay.to_f
		when "K"
			return pay.to_f + self.allowance(tax_code_number).to_f
		else
			return pay.to_f - self.allowance(tax_code_number).to_f
		end
	end


	def tax_due (taxable_pay, tax_code_letter)
		return 0 if taxable_pay <=0
		t = taxable_pay.floor.to_f
		puts "Taxable pay #{taxable_pay}; rounded down t = #{t}"

		case tax_code_letter
		when "BR"
			result = t * @c_G
		when "D0"
			result = t * @c_G1
		when "D1"
			result = t * @c_G2
		when "NT"
			result = 0

		else #calculate taxable pay according to the standard formula and rates
			if taxable_pay <= @c_v1
				result = t * @c_R1
			elsif taxable_pay <= @c_v2
				result = @c_k1 + (t - @c_c1) * @c_R2
			elsif taxable_pay <= @c_v3
				result = @c_k2 + (t - @c_c2) * @c_R3
			else
				result = @c_k3 + (t - @c_c3) * @c_R4
			end
		end

		return Round.down(result,2)

	end
end

class TaxCalculator

	def initialize ( this_tax_period, employee, pay_this, tax_code_number, tax_code_letter, basis=:cum )
		@cumulative = this_tax_period
		@employee = employee
		@noncumulative = TaxPeriod.new(@cumulative.year_ending, 1, @cumulative.periods_in_year)
		@pay_this = pay_this
		@m = this_tax_period.c_M  #regulatory limit percentage
		@total_pay = employee.cum_pay + pay_this
		@tax_code_number = tax_code_number
		@tax_code_letter = tax_code_letter
		@basis = basis
		@cumulative_taxable_pay = @cumulative.taxable_pay(@total_pay, @tax_code_number, @tax_code_letter)
		@noncumulative_taxable_pay = @noncumulative.taxable_pay(@pay_this, @tax_code_number, @tax_code_letter)
	end
		
	def tax_due_ytd_this
		if @basis == :cum
			@employee.cum_tax_liability - @employee.cum_tax_paid + @cumulative.tax_due(@cumulative_taxable_pay, @tax_code_letter)
		elsif @basis == :w1m1
			@noncumulative.tax_due(@noncumulative_taxable_pay, @tax_code_letter)
		end
	end

	def tax_deduction_this
		regulatory_limit = Round.down(@pay_this * @m,2)
		due = self.tax_due_ytd_this
		if @pay_this>0 and due > regulatory_limit
			return regulatory_limit
		else
			return due
		end
	end

end


# tom = Employee.new('Hood', 'Thomas Christian', Time.local(1984,1,6))
# fran = Employee.new('Milsom', 'Frances Harriet', Time.local(1983,1,23))

# tom.cum_pay, tom.cum_tax_paid, tom.cum_tax_liability = 0, 1000, 1000

# week, month = [], []
# (1..12).each {|p| month[p] = TaxPeriod.new("2015",p,12)}
# (1..52).each {|w| week[w] = TaxPeriod.new("2015",w,52)}

# taxcalc = TaxCalculator.new(month[1], tom, 500, 45, "0T", :cum)
# print taxcalc.tax_deduction_this