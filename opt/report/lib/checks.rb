require 'gpgme'
require 'json'

def check_privileged
  return Config.privileged_check_users.include?(ENV['USER'])
end

def get_checks(include_privileged, password)
  checks = []
  regular_check_files = Dir["#{Config.checksdir}/*.sh"]
  privileged_check_files = Dir["#{Config.checksdir}/*.sh.gpg"]

  # Gather data for regular checks
  regular_check_files.each do |checkfile|
    checks.append(get_check_data(checkfile))
  end

  # Decrypt privileged scripts if we've been given a password
  if include_privileged && password
    # Headless decryption
    @gpg = GPGME::Ctx.new(pinentry_mode: GPGME::PINENTRY_MODE_LOOPBACK, password: password)
    # Prevent caching of correct password so it needs to be provided everytime checks are run
    @gpg.set_ctx_flag('no-symkey-cache', 1)
    privileged_check_files.each do |priv_file|
      checks.append(get_check_data(priv_file, true, password))
    end
    @gpg.release
  end

  # Returns a hash of all available checks
  return checks
end

def get_check_data(checkfile, encrypted=false, password=nil)
  filename = File.basename(checkfile)
  if encrypted
    begin
      content = @gpg.decrypt(GPGME::Data.new(File.open(checkfile))).read
    rescue GPGME::Error::BadPassphrase, GPGME::Error::DecryptFailed
      puts "Failed to decrypt '#{filename}: Incorrect administrative password provided"
      exit 1
    end
  else
    content = File.read(checkfile)
  end
  
  description = content.each_line.find {|line| line =~ /^# Description: / }&.sub('# Description: ','')&.strip()
  if description.nil?
    description = "No description provided"
  end

  out = {"name" => filename, "description" => description, "content" => content}
  return out
end

def run_check(check_hash)
  # Take the name, description & content hash, create tempfile, execute script
  check_script = Tempfile.create
  check_script.puts(check_hash['content'])
  check_script.close

  output = `bash #{check_script.path} 2>&1`

  # Remove temp file
  File.unlink(check_script.path)

  return output
end

def check_to_status(output, prompt)
  # Identify if there is a status provided by the check and offer it to user
  status = YAML.load(output.lines.last) # Ensure we're only trying to load in a single line
  if is_valid_status(status)
    if (Config.warnings_only && status['type'] == 'warning') || ! Config.warnings_only
      if prompt.yes?("Add status '#{Config.status_symbol(status['type'])} #{status['message']}'?")
        outfile = "#{checkname}.yaml"
        file.open(outfile, 'a+') do |f|
          file.puts status.select {|k| k != 'checkname'}
        end
      end
    end
  end
end

def is_valid_status(status_hash)
  if status_hash.key?('checkname') && status_hash.key?('type') && status_hash.key?('message')
    return true
  else
    return false
  end
end
