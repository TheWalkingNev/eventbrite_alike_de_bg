class EventValidator < ActiveModel::Validator

  def validate(event)
    cannot_create_event_in_the_past(event)
    duration_should_be_multiple_of_five(event)
  end

  private

  def cannot_create_event_in_the_past(event)
    return unless event.start_date
    event.errors[:start_date] << "cannot create events in the past" if event.start_date < Time.now
  end

  def duration_should_be_multiple_of_five(event)
    return unless event.duration
    event.errors[:duration] << "duration should be multiple of five" unless event.duration % 5 == 0
  end

end
