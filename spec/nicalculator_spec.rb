require_relative './spec_helper'
require_relative '../ni'

describe NICalculator do 
	before {@nicalculator = NICalculator.new(year_ending: '2017', annual_periods: 52, pay_frequency: 1, category_letter: 'A')}

	it "should calculate category A NI correctly" do
		expect(nicalculator.ees_ni_payable(155.02)).to eq 0.01
	end

end