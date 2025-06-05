require 'yaml'

class Config
  class << self
    def appdir
      return File.expand_path(File.join(__FILE__,'../../'))
    end

    def accesslogsdir
      return "#{appdir}/var/accesslogs"
    end

    def checksdir
      return "#{appdir}/etc/checks"
    end

    def issuesdir
      return "#{appdir}/etc/issues"
    end
    
    def statusesdir 
      return "#{appdir}/etc/statuses"
    end

    def checkresultsdir
      return "#{appdir}/var/check-results"
    end

    def ratingsdir 
      return "#{appdir}/var/ratings"
    end

    def reportsdir
      return "#{appdir}/var/reports"
    end

    def data
      configfile = "#{appdir}/etc/config.yaml"
      if File.file?(configfile)
        @data = YAML.load_file(configfile) || {}
      else
        @data = {}
      end
      return @data
    end

    def confval(key, default)
      if data.key?(key)
        return data[key]
      else
        return default
      end
    end
    def always_report
      confval('always_report', true)
    end

    def metric_grace_period
      confval('metric_grace_period', 0)
    end

    def diagnostic_grace_period
      confval('diagnostic_grace_period', 0)
    end

    def hide_diagnostics
      confval('hide_diagnostics', true)
    end

    def hide_compare
      confval('hide_compare', true)
    end

    def always_send
      confval('always_send', true)
    end

    def enable_emojis
      confval('enable_emojis', true)
    end

    def privileged_check_users
      confval("privileged_check_users", ['root'])
    end

    def traffic_lights
      if enable_emojis
        return {2 => "😀" , 1 => "😐", 0 => "🙁"}
      else
        return {2 => "Great", 1 => "Okay", 0 => "Bad"}
      end
    end

    def status_symbol(type)
      if enable_emojis
        types = {"warning" => "⚠️", "working" => "✅", "other" => "ℹ️"}
      else
        types = {"warning" => "|!|", "working" => "|OK|", "other" => "|i|"}
      end

      case type
      when 'warning'
        icon = types['warning']
      when 'working'
        icon = types['working']
      when *
        icon = types['other']
      end
      return icon
    end

    def metrics_symbol(success)
      if enable_emojis
        if success
          return "🟢"
        else
          return "🟠"
        end
      else
        if success
          return "PASS:"
        else
          return "WARN:"
        end
      end
    end
  end
end
