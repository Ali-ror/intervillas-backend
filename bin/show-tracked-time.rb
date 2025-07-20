#!/usr/bin/env ruby

require "net/http"
require "json"
require "date"

ENDPOINT = URI "https://git.digineo.de/api/graphql".freeze

# https://git.digineo.de/-/profile/personal_access_tokens
PERSONAL_ACCESS_TOKEN = ENV.fetch("GITLAB_PERSONAL_ACCESS_TOKEN") {
  f = "tmp/glpat.txt"
  raise ArgumentError, "missing Gitlab PAT" unless File.exist?(f)

  File.read(f).chomp
}.freeze

# Sends GraphQL query to the server and parses it as JSON.
# Does not handle errors, and performs no pagination on its own.
def post(query)
  req = Net::HTTP::Post.new(ENDPOINT).tap { |r|
    r["Content-Type"]  = "application/json"
    r["Authorization"] = "Bearer #{PERSONAL_ACCESS_TOKEN}"

    r.body = {
      "operationName" => nil,
      "query"         => query,
      "variables"     => nil,
    }.to_json
  }

  Net::HTTP.start(ENDPOINT.hostname, ENDPOINT.port, use_ssl: ENDPOINT.scheme == "https") do |http|
    res = http.request(req)
    raise ArgumentError, res unless res.is_a?(Net::HTTPOK)

    JSON.parse(res.body).fetch("data")
  end
end

# Builds GraphQL TimeLog query.
def build_query(start_date:, end_date: nil, cursor: nil)
  vars  = [%(startDate: "#{start_date}T00:00:00+00:00")]
  vars << %(endDate: "#{end_date}T23:59:59+00:00") unless end_date.nil?
  vars << %(after: "#{cursor}")                    unless cursor.nil?

  <<~GRAPHQL.freeze
    {
      project(fullPath: "intervillas/support") {
        timelogs(#{vars.join(', ')}) {
          pageInfo {
            hasNextPage
            endCursor
          }
          nodes {
            issue { iid title }
            timeSpent
            spentAt
            user { name }
          }
        }
      }
    }
  GRAPHQL
end

# Simplified form of Gitlab's TimeLog record.
Timelog = Struct.new(:id, :title, :spent, :date, :user, keyword_init: true)

# Formats the given duration as a human-readable string.
def time_human(seconds)
  days, seconds  = seconds.divmod(8 * 60 * 60) # working day
  hours, seconds = seconds.divmod(60 * 60)
  minutes,       = seconds.divmod(60)

  return format("%dd %02d:%02d", days, hours, minutes) if days > 0

  format("%02d:%02d", hours, minutes)
end

# Converts ARGV into CLI arguments. Raises an error on unknown fields.
def parse_cli_arguments(*argv)
  args = {
    start_date: Time.now.strftime("%Y-%m-01"), # rubocop:disable Rails/TimeZone
    end_date:   Time.now.strftime("%Y-%m-%d"), # rubocop:disable Rails/TimeZone
  }
  loop do
    arg = argv.shift

    case arg
    when "-s", "--start" then args[:start_date] = argv.shift
    when "-e", "--end"   then args[:end_date]   = argv.shift
    when nil             then break # all arguments processed
    else raise "unexpected argument: #{arg.inspect}"
    end
  end
  args
end

## main ################################################################

args     = parse_cli_arguments(*ARGV)
timelogs = []  # result set
cursor   = nil # cursor-based pagination

# Fetch (all) data. This might issue multiple HTTP requests.
loop do
  data = post(build_query(**args, cursor:)).fetch("project").fetch("timelogs")

  timelogs += data.fetch("nodes").map { |log|
    Timelog.new \
      id:    log["issue"]["iid"],
      title: log["issue"]["title"],
      spent: log["timeSpent"],
      date:  DateTime.parse(log["spentAt"]),
      user:  log["user"]["name"]
  }

  info = data.fetch("pageInfo")
  break unless info.fetch("hasNextPage")

  cursor = info.fetch("endCursor")
end

if timelogs.size == 0
  puts "No data."
  exit
end

# Pretty-print time logs in tabular format, and tally the total time spent,
# and the time spent per user.
total      = 0
user_total = Hash.new { |h, k| h[k] = 0 }

lines = timelogs.sort_by(&:date).map { |log|
  total                += log.spent
  user_total[log.user] += log.spent

  format "%-15s   %-5s   %8s   %s   %s\n",
    log.user,
    "##{log.id}",
    time_human(log.spent),
    log.date.strftime("%Y-%m-%d %H:%M"),
    log.title
}

max_llen = lines.max_by(&:length).length
divider  = "-" * max_llen

printf "%-15s   %-5s   %8s   %-16s   %s\n",
  "User", "Issue", "Spent", "Date", "Title"

puts divider, lines, divider

if user_total.size > 1
  user_total.each do |user, spent|
    printf "%-15s  Total: %10s\n", user, time_human(spent)
  end
end

printf "%22s: %10s (%0.2fh)\n", "Total", time_human(total), total / 3600.0
