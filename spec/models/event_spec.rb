require 'rails_helper'

RSpec.describe Event, type: :model do

  before(:each) do
    @event = FactoryBot.create(:event)
  end

  it "has a valid factory" do
    expect(build(:event)).to be_valid
  end

  context "validation" do

    it "is valid with valid attributes" do
      expect(@event).to be_a(Event)
    end

    describe "#start_date" do
      it { expect(@event).to validate_presence_of(:start_date) }
      it "is not valid if start_date is after end_date" do
        invalid_event = FactoryBot.build(:event, start_date: Time.now - 1)
        expect(invalid_event).not_to be_valid
        expect(invalid_event.errors.include?(:start_date)).to eq(true)
      end
    end

    describe "#duration" do
      it { expect(@event).to validate_presence_of(:duration) }
      it { expect(@event).to validate_numericality_of(:duration).is_greater_than(0) }
      it "should be multiple of 5" do
        invalid_event = FactoryBot.build(:event, duration: 1)
        expect(invalid_event).not_to be_valid
        expect(invalid_event.errors.include?(:duration)).to eq(true)
      end
    end

  end
  
end
