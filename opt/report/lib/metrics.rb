require 'yaml' 

def check_metrics(metrics_file)
  metrics = YAML.load_file(metrics_file)
  metrics_out = {}
  metrics.each do |metric|
    metric_out = `#{metric['cmd']} 2>&1`.strip
    case metric['type']
    when 'lt'
      metric_success = metric_out.to_f < metric['value']
    when 'gt'
      metric_success = metric_out.to_f > metric['value']
    when 'equals'
      metric_success = metric_out.to_f == metric['value']
    when 'matches'
      metric_success = metric_out == metric['value']
    end
    metrics_out[metric['id']] = metric.merge({'output'=> metric_out, 'check'=> "#{metric['type']}: #{metric['value']}", 'success'=> metric_success})
  end
  return metrics_out
end

def failed_metrics(metrics)
  failures = metrics.find_all{ |m, d| d['success'] == false }
  return failures.count, failures
end

def report_metrics_detail(metrics)
  metrics.each do |metric, data|
    if data['success'] == true
      puts "  🟢 #{data['name']}"
    else
      puts "  🟠 #{data['name']}"
    end
  end
end
