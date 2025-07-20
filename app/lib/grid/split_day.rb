module Grid
  class SplitDay
    include Enumerable

    attr_reader :date
    attr_reader :ante, :overlap_ante
    attr_reader :post, :overlap_post

    def initialize(date)
      @date = date
      @ante = @post = nil
      @overlap_ante = @overlap_post = false
    end

    def ante=(obj)
      #raise "#{obj.inspect} blocked by #{ante.inspect} on #{date} (ante meridiem)" unless ante.nil?
      @overlap_ante = !ante.nil?
      @ante = obj
    end

    def post=(obj)
      #raise "#{obj.inspect} blocked by #{post.inspect} on #{date} (post meridiem)" unless post.nil?
      @overlap_post = !post.nil?
      @post = obj
    end

    def each
      # verdeckt von anderen Events, nichts zu tun
      return if ante == false && post == false
      d = date.strftime "%d"

      # ganztägig frei
      if empty?
        yield Cell.empty(d, 2)
        return
      end

      # vormittags frei
      yield Cell.empty(d, 1) if ante.nil?

      # Event-Block
      [ante, post].each do |curr|
        next unless Event === curr
        yield Cell.event(curr, overlap?)
      end

      # nachmittags frei
      yield Cell.empty(d, 1) if post.nil?

      return
    end

    def empty?
      ante.nil? && post.nil?
    end

    def overlap?
      overlap_ante || overlap_post
    end
  end
end
