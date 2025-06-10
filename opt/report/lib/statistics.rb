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

def all_statuses(type=nil)
  statuses = Dir.glob("#{Config.statusesdir}/*.yaml")
  status_details = []
  if statuses.count > 0
    statuses.each do |status|
      data = YAML.load_file(status)

      # Filter to specified type if present
      if type && data['type'] != type
        next
      end

      # Add timestamps if not present in file (and timestamps enabled)
      datemsg=""
      if Config.show_timestamps
        if ! data.key?('first_reported')
          data['first_reported'] = File.ctime(status).to_s
        end
        if ! data.key?('last_updated')
          data['last_updated'] = File.mtime(status).to_s
        end

        if DateTime.parse(data['first_reported']) == DateTime.parse(data['last_updated'])
          datemsg = "(First Reported: #{DateTime.parse(data['first_reported']).strftime("%Y-%m-%d %H:%M:%S")})"
        else
          datemsg = "(First Reported: #{DateTime.parse(data['first_reported']).strftime("%Y-%m-%d %H:%M:%S")}, Last Updated: #{DateTime.parse(data['last_updated']).strftime("%Y-%m-%d %H:%M:%S")})"
        end
      end

      # Generate status output
      sym = Config.status_symbol(data['type'])
      msg = data['message']

      # Add to statuses
      status_details.append("#{sym} #{msg} #{datemsg}")
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
