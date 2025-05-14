require 'yaml'

def all_reports(reportsdir, hours=1)
  reports = Dir.glob("#{reportsdir}/.user-report-*.log").select {|f| File.ctime(f) > (Time.now - (3600 * hours)) }.map{ |f| Report.new(f)}
  report_summary = {}
  report_summary.default_proc = proc { 0 } # This allows for += to a key that doesn't exist
  reports.each do |report|
    report_summary[report.log['meta']['issue_id']] += 1
  end
  return report_summary
end

def all_statuses(statusesdir)
  statuses = Dir.glob("#{statusesdir}/*.yaml")
  status_details = []
  if statuses.count > 0
    statuses.each do |status|
      data = YAML.load_file(status)
      case data['type']
      when 'warning'
        icon = "⚠️"
      when 'working'
        icon = "✅"
      when *
        icon = "ℹ️"
      end
      status_details.append("#{icon} #{data['message']}")
    end
  end
  return status_details
end

def all_ratings(ratingsdir, hours=1)
  recent_ratings = Dir.glob("#{ratingsdir}/.user-rating-*.log").select {|f| File.ctime(f) > (Time.now - (3600 * hours)) }.map{ |f| File.read(f).strip}

  ratings = {"😀" => recent_ratings.tally["2"] || 0, "😐" => recent_ratings.tally["1"] || 0, "🙁" => recent_ratings.tally["0"] || 0}
  #ratings = {"Good" => recent_ratings.tally["2"] || 0, "Okay" => recent_ratings.tally["1"] || 0, "Bad " => recent_ratings.tally["0"] || 0}
  return ratings
end
