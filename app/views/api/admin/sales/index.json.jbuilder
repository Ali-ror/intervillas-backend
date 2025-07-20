json.call(@analysis, :date)

json.year to_currency_hash(@analysis.year)
json.year_net to_currency_hash(@analysis.year_net)
json.prev_year to_currency_hash(@analysis.prev_year)
json.prev_year_net to_currency_hash(@analysis.prev_year_net)
json.change to_currency_hash(@analysis.change)
json.change_net to_currency_hash(@analysis.change_net)
