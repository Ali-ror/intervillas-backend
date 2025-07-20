class DownpaymentSecurity
  # Wenn eine Anzahlung >= `abs` oder >= `rel`*total vorliegt, können wir dies
  # als akzeptable Sicherheit hinnehmen und in der UI einen Toggle-Button zum
  # Ausblenden der "überfälligen" Zahlung anbieten.
  REL_THRESHOLD = 0.7
  ABS_THRESHOLD = 500

  # keep in sync with #acceptable?
  ACCEPTABLE_QUERY = <<~SQL.squish.freeze
    late = 'f' and total_payments < downpayment_sum and (
      total_payments >= :abs or
      total_payments >= :rel * downpayment_sum
    )
  SQL
  private_constant :ACCEPTABLE_QUERY

  def self.acceptable_scope(scope)
    scope.where ACCEPTABLE_QUERY,
      rel: REL_THRESHOLD,
      abs: ABS_THRESHOLD
  end

  attr_reader :late, :paid_sum, :downpayment_sum

  def initialize(late:, paid_sum:, downpayment_sum:)
    @late            = late
    @paid_sum        = paid_sum
    @downpayment_sum = downpayment_sum
  end

  # keep in sync with ACCEPTABLE_QUERY
  def acceptable?
    !late && paid_sum < downpayment_sum && (
      paid_sum >= ABS_THRESHOLD ||
      paid_sum >= REL_THRESHOLD * downpayment_sum
    )
  end
end
