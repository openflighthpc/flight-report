require 'gpgme'

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
      checks.append(get_check_data(priv_file, encrypted: true, password: password))
    end
    @gpg.release
  end

  # Get site checks
  if Config.sitechecksdir
    site_check_files = Dir["#{Config.sitechecksdir}/*.sh"]

    # Gather data for site checks
    site_check_files.each do |checkfile|
      checks.append(get_check_data(checkfile, source: "Site"))
    end
  end

  # Returns a hash of all available checks
  return checks
end

def get_check_data(checkfile, encrypted: false, password: nil, source: "Alces")
  filename = File.basename(checkfile)
  if encrypted
    gpg_ver = `gpg --version |head -1 |sed 's/gpg (GnuPG) //g'`.to_f
    if gpg_ver < 2.1 || Config.force_gpg_cli
      content = `gpg -q -d --batch --passphrase "#{password}" --armor #{checkfile}`
      if content.empty?
        puts "Incorrect password or invalid (empty) script"
        exit 1
      end
    else
      begin
        content = @gpg.decrypt(GPGME::Data.new(File.open(checkfile))).to_s
      rescue GPGME::Error::BadPassphrase, GPGME::Error::DecryptFailed
        puts "Failed to decrypt '#{filename}: Incorrect administrative password provided"
        exit 1
      end
    end
  else
    content = File.read(checkfile)
  end

  # Questions
  questionsfile = checkfile + '.questions'
  if File.file?(questionsfile)
    questions = YAML.load_file(questionsfile)
  else
    questions = nil
  end

  description = content.each_line.find {|line| line =~ /^# Description: / }&.sub('# Description: ','')&.strip()
  if description.nil?
    description = "No description provided"
  end

  name = "[#{source}] #{filename}"

  out = {"name" => name, "description" => description, "content" => content, "questions" => questions}
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
