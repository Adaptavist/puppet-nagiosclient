#!/usr/bin/env ruby

require 'rubygems'
require 'mysql'
require 'optparse'

#define functions
def ok(message)
   puts "OK - #{message}\n"
   exit 0
end

def warning(message)
   puts "WARNING - #{message}\n"
   exit 1
end

def critical(message)
   puts "CRITICAL - #{message}\n"
   exit 2
end

def unknown(message)
  puts "UNKNOWN - #{message}\n"
  exit 3
end

#define variables
expected_rows=1
warn = 60
crit = 120

#default mysql connection variables, can be overwritten by command line arguments
db_host  = "127.0.0.1" #do not use localhost as the mysql client library defaults to socket with localhost!
db_user  = ""
db_pass  = ""
db_name  = ""
db_port  = 3306

#deal with arguments
OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"

  opts.on("-u", "--user USER", String, "Username") do |user|
    db_user = user
  end

  opts.on("-p", "--password PASS", String, "Password") do |pass|
    db_pass = pass
  end

  opts.on("-h", "--host HOST", String, "Host") do |host|
    db_host = host
  end

  opts.on("-d", "--database DB", String, "Database Name") do |db|
    db_name = db
  end

  opts.on("-t", "--port PORT", String, "Connection Port") do |port|
    db_port = port.to_i
  end

end.parse!

begin
	db = Mysql.new(db_host, db_user, db_pass, db_name, db_port)
	results = db.query 'show slave status'

	if results.nil?
    critical "No slave status, this server is not a slave??."
  else
    if results.num_rows != expected_rows
      critical "Query returned #{results.num_rows} rows"
    end

    results.each_hash do |row|
      if row['Slave_IO_Running'] != "Yes"
        critical "Replication problem: Slave IO not running!"
      elsif row['Slave_SQL_Running'] != "Yes"
        critical "Replication problem: Slave SQL not running!"
      end

      replication_delay = row['Seconds_Behind_Master'].to_i
      if replication_delay > warn && replication_delay <= crit
        warning "Replication problem: Seconds_Behind_Master=#{replication_delay}"
      elsif replication_delay >= crit
        critical "Replication problem: Seconds_Behind_Master=#{replication_delay}"
      else
        ok "#{row['Slave_IO_State']}, replicating host #{row['Master_Host']}:#{row['Master_Port']}"
      end
    end
  end


  rescue Mysql::Error => e
    unknown "Mysql Error - Error code: #{e.errno} Error message: #{e.error}"
  rescue => e
    unknown "General Error - #{e}"
  ensure
	  db.close if db
end