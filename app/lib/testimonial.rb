class Testimonial
  ENTRIES = YAML.load(File.read('db/testimonials.yml')) rescue []

  delegate :each_slice, to: :ENTRIES
  delegate :shuffle, to: :ENTRIES

  def self.all
    new
  end

  def self.to_reviews
    list = []

    ENTRIES.each.with_index do |e, i|
      date  = Date.strptime e['date'], '%d.%m.%y'
      villa = Villa.where('UPPER(name) = ?', e['villa']).first
      list.push "%d: %d" % [i, villa.bookings.where('state = ? AND end_date > ? AND end_date <= ?', 'full_payment_received', date, date+2.weeks).count]
    end

    list
  end

end
