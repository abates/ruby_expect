RubyExpect
==========
[![Gem Version](https://badge.fury.io/rb/ruby_expect.svg)](https://badge.fury.io/rb/ruby_expect)
[![Build Status](https://travis-ci.org/abates/ruby_expect.svg?branch=develop)](https://travis-ci.org/abates/ruby_expect)
[![Dependency Status](https://gemnasium.com/badges/github.com/abates/ruby_expect.svg)](https://gemnasium.com/github.com/abates/ruby_expect)

Introduction
------------

This is a simple expect API written in pure ruby. Part of this library includes a simple procedure DSL
for creating sequences of expect/send behavior. 

Examples
--------

### SSH to a host and run a command
This example will use the system ssh binary and connect to a host.  Upon connecting it will
execute a command and wait for the response then exit.  The response from the command will be
parsed and printed to the screen.

```ruby
#!/usr/bin/ruby

require 'ruby_expect'

username = 'username'
password = 'password'
hostname = 'hostname'

exp = RubyExpect::Expect.spawn("/usr/bin/ssh #{username}@#{hostname}")

exp.procedure do
  retval = 0
  while (retval != 2)
    retval = any do
      expect /Are you sure you want to continue connecting \(yes\/no\)\?/ do
        send 'yes'
      end

      expect /password:\s*$/ do
        send password
      end

      expect /\$\s*$/ do
        send 'uptime'
      end
    end
  end

  # Expect each of the following
  each do
    expect /load\s+average:\s+\d+\.\d+,\s+\d+\.\d+,\s+\d+\.\d+/ do # expect the output of uptime
      puts last_match.to_s
    end

    expect /\$\s+$/ do # shell prompt
      send 'exit'
    end
  end
end
```

### Interact with a local script
This example runs a script and interacts with it
```ruby
#!/usr/bin/ruby

require 'ruby_expect'

root_password = 'root_password'
new_root_password = 'new_password'

exp = RubyExpect::Expect.spawn('mysql_secure_installation', :debug => true)

exp.procedure do
  each do
    expect "Enter current password for root (enter for none):" do
      send root_password
    end

    expect "Change the root password? [Y/n]" do
      send "y"
    end

    expect "New password:" do
      send new_root_password
    end

    expect "Re-enter new password:" do
      send new_root_password
    end

    expect "Remove anonymous users?" do
      send "y"
    end

    expect "Disallow root login remotely?" do
      send "y"
    end

    expect "Remove test database and access to it?" do
      send "y"
    end

    expect "Reload privilege tables now?" do
      send "y"
    end
  end
end

puts "Ended expect script."
```


### SSH to a host and interact
This example will spawn ssh and login to the host.  Once logged in, the interact
method is called which returns control to the user and allows them to interact
directly with the remote system

```ruby
#!/usr/bin/ruby

require 'ruby_expect'

username = 'username'
password = 'password'
hostname = 'hostname'

exp = RubyExpect::Expect.spawn("/usr/bin/ssh #{username}@#{hostname}")
exp.procedure do
  retval = 0
  while (retval != 2)
    retval = any do
      # Accept the key if it isn't already known
      expect /Are you sure you want to continue connecting \(yes\/no\)\?/ do
        send 'yes'
      end

      # Send the password at the prompt
      expect /password:\s*$/ do
        send password
      end

      # Expect the shell prompt
      expect /\$\s*$/ do
        send ""
      end
    end
  end
end

# Pass control back to the user
exp.interact
```
