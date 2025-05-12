require 'yaml'

class Report
  attr_accessor :log, :logname

  def initialize(file=nil)
    username = ENV['USER']
    issue_date = Time.now.strftime("%Y%m%d")
    issue_time = Time.now.strftime("%H%M%S")

    if file
      @log = YAML.load_file(file)
    else
      @log = {
        'meta' => {
          'issue_id' => nil,
          'username' => username,
          'reported_at' => Time.now.strftime("%Y%m%dT%H%M%S"),
          'issue_at' => "#{issue_date}T#{issue_time}",
          'rating' => nil
        },
        'diagnostics' => {
          'general' => {},
          'issue' => {
            'script_md5' => nil,
            'answers' => {},
            'output' => nil
          }
        },
        'metrics' => {}
      }
    end
  end

  def ratingfilename
    return ".user-rating-#{@log['meta']['username']}-#{@log['meta']['issue_at'].split('T').join('-')}.log"
  end

  def reportfilename
    return ".user-report-#{@log['meta']['issue_id']}-#{@log['meta']['username']}-#{@log['meta']['issue_at'].split('T').join('-')}.log"
  end

  def outputs
    general_out = @log['diagnostics']['general'].map{ |script, data| data['output']}.join("\n\n")
    issue_out = @log['diagnostics']['issue']['output']
    return [general_out, issue_out].join("\n\n")
  end
end
