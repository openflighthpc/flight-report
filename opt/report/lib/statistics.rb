require 'yaml'
require_relative 'config'

def all_reports(hours=1)
  reports = Dir.glob("#{Config.reportsdir}/.user-report-*.log").select {|f| File.ctime(f) > (Time.now - (3600 * hours)) }.map{ |f| Report.new(f)}
  report_summary = {}
  report_summary.default_proc = proc { 0 } # This allows for += to a key that doesn't exist
  reports.each do |report|
    report_summary[report.log['meta']['issue_id']] += 1
  end
  return report_summary
end

def all_statuses
  statuses = Dir.glob("#{Config.statusesdir}/*.yaml")
  status_details = []
  if statuses.count > 0
    statuses.each do |status|
      data = YAML.load_file(status)
      status_details.append("#{Config.status_symbol(data['type'])} #{data['message']}")
    end
  end
  return status_details
end

def all_ratings(hours=1)
  recent_ratings = Dir.glob("#{Config.ratingsdir}/.user-rating-*.log").select {|f| File.ctime(f) > (Time.now - (3600 * hours)) }.map{ |f| File.read(f).strip}

  ratings = {Config.traffic_lights[2] => tally(recent_ratings)["2"] || 0, Config.traffic_lights[1] => tally(recent_ratings)["1"] || 0, Config.traffic_lights[0] => tally(recent_ratings)["0"] || 0}
  return ratings
end

def tally(arry)
  return arry.group_by(&:itself).transform_values(&:count)
end
